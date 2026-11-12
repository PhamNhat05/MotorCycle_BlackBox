"""Ordered experiment: TRAIN → real VALIDATION → freeze → real TEST → stress."""
from pathlib import Path
from datetime import datetime, timezone
import json
import time
import joblib
import numpy as np
import pandas as pd
import sklearn
from .io import sha256, write_json
from .calibration import estimate_train_prior
from .dataset import AugmentedSource, FeatureStore
from .training import fit, score_records, select_threshold, selection_key
from .metrics import summarize, window_metrics, event_metrics, alarms
from .features import FEATURE_NAMES
from .report import create_report


def run(root, output, augmentation_dir=None, original_run=None, allow_partial=False, resume=False):
    root, output = Path(root).resolve(), Path(output).resolve()
    settings = json.loads((root / "config/settings.json").read_text())
    parents = json.loads((root / "config/parents.json").read_text())
    if settings["rf"]["n_estimators"] != 100: raise ValueError("This project fixes RF at 100 trees")
    if [sum(p["ai_split"] == s for p in parents) for s in ["train", "validation", "test"]] != [6, 2, 2]:
        raise ValueError("Expected the declared six/two/two original-parent split")
    if len({p["key"] for p in parents}) != 10: raise ValueError("Duplicate parent identities")
    if output.exists() and any(output.iterdir()) and not resume:
        raise ValueError("Output already exists; choose a new --out, or use --resume with unchanged inputs")
    output.mkdir(parents=True, exist_ok=True)
    def log(message):
        print(message, flush=True)
        with (output / "RUN_LOG.txt").open("a", encoding="utf-8") as f: f.write(message+"\n")
    def stage(name):
        log(name)
        with (output / "STAGES.jsonl").open("a", encoding="utf-8") as f:
            f.write(json.dumps({"stage": name, "utc": datetime.now(timezone.utc).isoformat()})+"\n")
    stage("VALIDATE_CONFIGURATION_AND_PARENT_METADATA")
    aug = AugmentedSource(augmentation_dir, parents, settings, original_run, allow_partial) if augmentation_dir else None
    signature = {"settings": settings, "parents": parents,
        "code_sha256": {p.name: sha256(p) for p in sorted((root / "rf100").glob("*.py"))},
        "augmentation_manifest_sha256": aug.fingerprint if aug else None,
        "frozen_generator_sha256": aug.frozen_hash if aug else None}
    signature_file = output / "RUN_SIGNATURE.json"
    if resume and signature_file.is_file() and json.loads(signature_file.read_text()) != signature:
        raise ValueError("Resume input/code/configuration changed; use a new result directory")
    write_json(signature_file, signature); write_json(output / "SETTINGS.json", settings)
    stage("ESTIMATE_GYRO_PRIOR_FROM_SIX_TRAIN_PARENTS_ONLY")
    calibration = estimate_train_prior(root, parents)
    write_json(output / "CALIBRATION_TRAIN_ONLY.json", calibration)
    if aug:
        write_json(output / "AUGMENTATION_REBASE_INFO.json", {
            "generator_build_keys": aug.frozen["K"]["build_keys"],
            "ai_train_keys": calibration["train_parent_keys"],
            "generator_bias": aug.frozen["K"]["bias"],
            "new_train_gyro_prior_deg_s": calibration["gyro_bias_deg_s"],
            "operation": "Replace old centripetal lever-arm term with TRAIN-prior term; derivative term unchanged",
            "original_csv_bytes_modified": False})
    store = FeatureStore(root, output, settings, calibration, aug)
    split_rows = [{"parent": p["key"], "ai_split": p["ai_split"], "generator_split": p["generator_split"],
                   "contains_fall": p["record_contains_fall"], "original_files": 1,
                   "augmented_expected": 100, "augmented_available": len(aug.rows[p["key"]]) if aug else 0}
                  for p in parents]
    pd.DataFrame(split_rows).to_csv(output / "DATA_SPLIT.csv", index=False)
    counts = []
    for split in ["train", "validation", "test"]:
        rows = [r for r in split_rows if r["ai_split"] == split]
        counts.append({"ai_split": split, "original_files": len(rows),
                       "augmented_expected": sum(r["augmented_expected"] for r in rows),
                       "augmented_available": sum(r["augmented_available"] for r in rows),
                       "total_available_files": len(rows)+sum(r["augmented_available"] for r in rows),
                       "augmentation_role": "fitting and fitted diagnostics" if split == "train" else "post-freeze stress only"})
    split_summary = pd.DataFrame(counts); split_summary.to_csv(output / "SPLIT_SUMMARY.csv", index=False)
    log(split_summary.to_string(index=False))
    stage("READ_TRAIN_ORIGINALS_AND_TRAIN_AUGMENTATION")
    train = [store.load(p) for p in parents if p["ai_split"] == "train"]
    augmented_train = []
    if aug:
        for p in parents:
            if p["ai_split"] != "train": continue
            for row in aug.rows[p["key"]]:
                augmented_train.append(store.load(p, row))
                if len(augmented_train) % 25 == 0: log(f"TRAIN augmentation: {len(augmented_train)} recordings loaded")
    stage("READ_REAL_VALIDATION_ONLY")
    validation = [store.load(p) for p in parents if p["ai_split"] == "validation"]
    candidates = {}; candidate_rows = []; threshold_rows = []
    conditions = [("real_only__rf100", train)]
    if augmented_train: conditions.append(("mixed__rf100", train+augmented_train))
    (output / "models").mkdir(exist_ok=True)
    for name, training_records in conditions:
        stage(f"FIT_{name}"); start = time.perf_counter()
        model, details = fit(training_records, settings)
        fit_seconds = time.perf_counter()-start
        best, search = select_threshold(model, validation, settings)
        bundle = {"model": model, "candidate_id": name, "threshold": best["threshold"],
                  "settings": settings, "calibration": calibration, "feature_names": FEATURE_NAMES,
                  "sklearn_version": sklearn.__version__, "parent_manifest": parents,
                  "fit_details": details, "fit_seconds": fit_seconds, "validation": best,
                  "augmentation_used": bool(name.startswith("mixed"))}
        candidates[name] = bundle; joblib.dump(bundle, output / "models" / f"{name}.joblib", compress=3)
        candidate_rows.append({"candidate": name, "trees": details["actual_trees"],
            "features": 24, "fit_recordings": len(training_records), "fit_windows": details["fit_windows"],
            "fit_seconds": fit_seconds, **best})
        threshold_rows.extend({"candidate": name, **r} for r in search)
    # Selection sees real VALIDATION only; exact condition ties prefer mixed.
    selected = max(candidates, key=lambda name: (*selection_key(candidates[name]["validation"]), name.startswith("mixed")))
    bundle = candidates[selected]
    frozen = {"selected_candidate": selected, "threshold": bundle["threshold"],
              "selection_source": "real_validation_only", "numeric_test_used_for_selection": False,
              "tie_break": "event recall, F2, fewer false alarm events, shorter nonnegative contact delay, mixed condition",
              "guard_matching_interval": "T1-0.5 seconds through T2+2 seconds",
              "validation": bundle["validation"]}
    write_json(output / "MODEL_SELECTION_FROZEN.json", frozen)
    frozen_hash = sha256(output / "MODEL_SELECTION_FROZEN.json")
    (output / "MODEL_SELECTION_FROZEN.sha256").write_text(frozen_hash+"\n")
    joblib.dump(bundle, output / "best_model.joblib", compress=3)
    pd.DataFrame(candidate_rows).to_csv(output / "VALIDATION_CANDIDATES.csv", index=False)
    pd.DataFrame(threshold_rows).to_csv(output / "VALIDATION_THRESHOLD_SEARCH.csv", index=False)
    stage("SELECTION_FROZEN_BEFORE_NUMERIC_REAL_TEST_READ")
    test = [store.load(p) for p in parents if p["ai_split"] == "test"]
    comparison = []
    for name, candidate in candidates.items():
        score_records(candidate["model"], test)
        comparison.append({"candidate": name, "selected_before_test": name == selected,
                           **summarize(test, candidate["threshold"], settings)})
    pd.DataFrame(comparison).to_csv(output / "TEST_COMPARISON_PREDECLARED_MODELS.csv", index=False)
    stage("EVALUATE_SELECTED_MODEL_ON_ORIGINALS_AND_FITTED_TRAIN_VARIANTS")
    originals = train+validation+test
    score_records(bundle["model"], originals)
    score_records(bundle["model"], augmented_train)
    selected_threshold = bundle["threshold"]
    summaries = []
    for split, records in [("train_original_fit_diagnostic", train),
                            ("validation_original_selection", validation), ("test_original", test)]:
        summaries.append({"evaluation": split, **summarize(records, selected_threshold, settings)})
    if augmented_train:
        summaries.append({"evaluation": "train_augmented_fit_diagnostic", **summarize(augmented_train, selected_threshold, settings)})
    heldout_aug = []
    if aug:
        stage("POST_FREEZE_AUGMENTED_VALIDATION_AND_TEST_STRESS")
        for split in ["validation", "test"]:
            records = []
            for p in parents:
                if p["ai_split"] != split: continue
                for row in aug.rows[p["key"]]:
                    records.append(store.load(p, row))
                    if len(records) % 25 == 0: log(f"{split.upper()} augmentation stress: {len(records)} recordings loaded")
            if records:
                score_records(bundle["model"], records); heldout_aug.extend(records)
                summaries.append({"evaluation": f"{split}_augmented_stress", **summarize(records, selected_threshold, settings)})
    every_record = originals+augmented_train+heldout_aug
    summaries.append({"evaluation": "all_data_diagnostic_includes_train", **summarize(every_record, selected_threshold, settings)})
    per_file = []; combined = []; offset = 0.0
    for r in every_record:
        r["alarm"] = alarms(r["t"], r["probability"] >= selected_threshold, settings["alarm_cooldown_s"])
        per_file.append({"record": r["id"], "parent": r["parent"]["key"], "ai_split": r["parent"]["ai_split"],
            "kind": r["kind"], "group": r["group"],
            **window_metrics(r["y"], r["probability"], selected_threshold),
            **event_metrics(r["t"], r["probability"], r["parent"], selected_threshold, settings)})
        pred = pd.DataFrame({"time_s": r["t"], "window_start_s": r["t"]-(settings["window_s"]-1/settings["sampling_hz"]),
            "true_label": r["y"], "scored": r["y"]>=0, "probability_fall": r["probability"],
            "predicted_fall": (r["probability"]>=selected_threshold).astype(int), "alarm": r["alarm"].astype(int)})
        directory = output / "predictions" / r["kind"]; directory.mkdir(parents=True, exist_ok=True)
        pred.to_csv(directory / f"{r['id']}.csv", index=False)
        if r["kind"] == "original":
            merged = pred.copy(); merged.insert(0, "parent", r["parent"]["key"])
            merged.insert(1, "ai_split", r["parent"]["ai_split"])
            merged.insert(2, "session_time_s", offset+r["t"]-r["parent"]["first_time_s"])
            merged.insert(3, "independent_session_reset", [True]+[False]*(len(merged)-1))
            combined.append(merged)
            offset += r["parent"]["last_time_s"]-r["parent"]["first_time_s"]+1.0
    pd.concat(combined, ignore_index=True).to_csv(output / "ORIGINALS_SEQUENTIAL_TIMELINE.csv", index=False)
    if sha256(output / "MODEL_SELECTION_FROZEN.json") != frozen_hash:
        raise RuntimeError("Frozen model choice changed during TEST evaluation")
    info = {k: v for k, v in bundle.items() if k not in ["model", "parent_manifest"]}
    info.update({"trees": len(bundle["model"].estimators_), "model_file_bytes": (output / "best_model.joblib").stat().st_size,
                 "selection_sha256": frozen_hash, "test_independent_fall_events": 1,
                 "hardware_latency_measured": False,
                 "partial_mode_allowed": bool(allow_partial),
                 "partial_augmentation": bool(aug and sum(len(v) for v in aug.rows.values()) != 1000)})
    write_json(output / "BEST_MODEL_INFO.json", info)
    stage("WRITE_HIGH_CONTRAST_REPORT_AND_FIGURES")
    create_report(output, root, bundle, originals, summaries, split_summary,
                  pd.DataFrame(candidate_rows), per_file, store.audit)
    stage("COMPLETE")
    (root / "results").mkdir(exist_ok=True)
    try:
        portable_output = output.relative_to(root)
    except ValueError:
        portable_output = output
    (root / "results/LATEST_RUN.txt").write_text(str(portable_output), encoding="utf-8")
    log(f"REPORT: {output / 'REPORT.html'}")
    return output
