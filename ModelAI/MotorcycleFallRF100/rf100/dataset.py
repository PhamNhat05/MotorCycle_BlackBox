"""Bind every synthetic recording to its measured parent before any fitting."""
from pathlib import Path
import json
import hashlib
import numpy as np
import pandas as pd
from .io import sha256, read_imu, verify_parent
from .features import extract
from .calibration import rebase_position_effect
from .metrics import labels


def resolve_augmented(path):
    path = Path(path).expanduser().resolve()
    if (path / "VARIANT_MANIFEST.csv").is_file(): return path
    results = path / "AUGMENTED" / "results"
    if not results.is_dir():
        raise ValueError("Choose MotorcycleIMULab or an AUGMENTED/results/RUN_... directory")
    pointer = results / "LATEST_RUN.txt"
    if pointer.is_file():
        selected = results / pointer.read_text(encoding="utf-8-sig").strip()
        if (selected / "VARIANT_MANIFEST.csv").is_file(): return selected
    raise ValueError("No augmentation run exists. Execute RUN_AUGMENT in MATLAB first")


class AugmentedSource:
    def __init__(self, path, parents, settings, original_run=None, allow_partial=False):
        self.directory = resolve_augmented(path)
        self.fingerprint = sha256(self.directory / "VARIANT_MANIFEST.csv")
        link = json.loads((self.directory / "ORIGINAL_RUN.json").read_text(encoding="utf-8-sig"))
        if original_run:
            original = Path(original_run).expanduser().resolve()
        else:
            # Standard supplied layout: project/AUGMENTED/results/RUN_... .
            original = self.directory.parents[2] / "ORIGINAL/results" / link["original_run_name"]
        lock = original / "FROZEN_CONFIGURATION.json"
        if not lock.is_file():
            raise ValueError("Cannot find the original frozen configuration; supply --original-run")
        self.frozen_hash = sha256(lock)
        if self.frozen_hash != link["frozen_sha256"]:
            raise ValueError("Original/augmented frozen configuration hashes differ")
        self.frozen = json.loads(lock.read_text(encoding="utf-8-sig"))
        c, k = self.frozen["C"], self.frozen["K"]
        if (c.get("schema") != 2 or c.get("method") != "FULL_RECORD_CONDITIONAL_KINEMATIC_RECONSTRUCTION"
            or self.frozen.get("test_values_used_for_common_configuration") is not False
            or k.get("test_values_used") is not False):
            raise ValueError("Unsupported or test-contaminated generator configuration")
        if set(k["build_keys"]) != {p["key"] for p in parents if p["generator_split"] == "build"}:
            raise ValueError("Generator BUILD parents differ from this dataset")
        table = pd.read_csv(self.directory / "VARIANT_MANIFEST.csv")
        required = {"ParentKey", "Group", "VariantIndex", "Materialized", "Samples", "ParentSplit"}
        if not required.issubset(table.columns): raise ValueError("Unexpected variant manifest columns")
        lookup = {p["key"]: p for p in parents}
        self.rows = {p["key"]: [] for p in parents}; self.pending = 0
        seen = set()
        for row in table.to_dict("records"):
            key, group, index = str(row["ParentKey"]), str(row["Group"]), int(row["VariantIndex"])
            if key not in lookup or group not in settings["expected_group_counts"] or not 1 <= index <= 100:
                raise ValueError("Unknown variant identity")
            identity = (key, index)
            if identity in seen: raise ValueError(f"Duplicate variant: {identity}")
            seen.add(identity)
            p = lookup[key]
            if str(row["ParentSplit"]) != p["generator_split"] or int(row["Samples"]) != p["samples"]:
                raise ValueError("Variant parent metadata mismatch")
            done = str(row["Materialized"]).lower() in {"true", "1", "1.0"}
            if not done:
                self.pending += 1
                if allow_partial: continue
                raise ValueError("Augmentation is incomplete; finish MATLAB export or use --allow-partial")
            stem = self.directory / "records" / key / group / f"variant_{index:03d}"
            row.update(path=Path(str(stem)+".csv"), definition_path=Path(str(stem)+".json"),
                       completion_path=Path(str(stem)+".complete.json"), ai_split=p["ai_split"])
            self.rows[key].append(row)
        if not allow_partial:
            for p in parents:
                rows = self.rows[p["key"]]
                if len(rows) != settings["expected_variants_per_parent"]:
                    raise ValueError(f"Expected 100 completed variants for {p['key']}")
                for group, expected in settings["expected_group_counts"].items():
                    if sum(r["Group"] == group for r in rows) != expected:
                        raise ValueError("Variant group counts differ from 34/33/33")
        self.model_hashes = dict(zip([p["key"] for p in parents], link["original_model_sha256"]))
        if not any(self.rows.values()): raise ValueError("No completed augmented recordings")

    def definition(self, row, parent):
        path = row["path"]
        for p in (path, row["definition_path"], row["completion_path"]):
            if not p.is_file(): raise FileNotFoundError(f"Incomplete variant output: {p}")
        complete = json.loads(row["completion_path"].read_text(encoding="utf-8-sig"))
        d = json.loads(row["definition_path"].read_text(encoding="utf-8-sig"))
        csv_hash = sha256(path)
        if (not complete.get("all_outputs_complete") or complete.get("csv_sha256") != csv_hash
            or complete.get("definition_sha256") != sha256(row["definition_path"])):
            raise ValueError(f"Variant checksum/completion mismatch: {path}")
        if (d.get("parent_key") != parent["key"] or d.get("parent_split") != parent["generator_split"]
            or int(d.get("variant_index", -1)) != int(row["VariantIndex"])
            or d.get("group") != row["Group"] or d.get("samples") != parent["samples"]
            or d.get("record_contains_fall") != parent["record_contains_fall"]
            or d.get("parent_model_sha256") != self.model_hashes[parent["key"]]
            or d.get("frozen_configuration_sha256") != self.frozen_hash
            or d.get("scope") != "SAME_LATENT_MOTION_CONSTANT_BIAS_AND_FIXED_BODY_POSITION"
            or not d.get("timing_preserved") or not d.get("mounting_rotation_preserved")
            or d.get("acc_bias_units") != "m/s^2" or d.get("gyro_bias_units") != "deg/s"):
            raise ValueError(f"Unsupported variant provenance: {path}")
        bias = np.asarray(d["bias_delta"], float); dr = np.asarray(d["position_delta_body_m"], float)
        if bias.shape != (6,) or not np.isfinite(bias).all() or np.any(np.abs(bias) > np.array([10]*3+[0.2]*3)+1e-8):
            raise ValueError("Invalid augmentation bias bounds")
        if row["Group"] == "bias_only" and not np.allclose(dr, 0): raise ValueError("Bias-only variant has position shift")
        if row["Group"] == "position_only" and not np.allclose(bias, 0): raise ValueError("Position-only variant has added bias")
        return d, csv_hash


class FeatureStore:
    def __init__(self, root, output, settings, calibration, augmentation=None):
        self.root, self.settings, self.calibration, self.augmentation = root, settings, calibration, augmentation
        self.cache = output / "feature_cache"; self.cache.mkdir(parents=True, exist_ok=True)
        code = "".join(sha256(p) for p in sorted((root / "rf100").glob("*.py")))
        value = json.dumps([settings, calibration, code], sort_keys=True)
        self.signature = hashlib.sha256(value.encode()).hexdigest()
        self.audit = []

    def load(self, parent, row=None):
        generated = row is not None; d = None
        if generated:
            path = row["path"]; d, checksum = self.augmentation.definition(row, parent)
            identity = f"{parent['key']}__{row['Group']}__{int(row['VariantIndex']):03d}"
            extra = self.augmentation.frozen_hash + sha256(row["definition_path"])
        else:
            path = self.root / parent["relative_path"]; checksum = sha256(path)
            if checksum != parent["sha256"]: raise ValueError(f"Measured checksum mismatch: {path}")
            identity = parent["key"]; extra = ""
        fingerprint = hashlib.sha256((self.signature+checksum+extra+json.dumps(parent, sort_keys=True)).encode()).hexdigest()
        target = self.cache / f"{identity}_{fingerprint[:16]}.npz"
        correction = 0.0
        if target.is_file():
            with np.load(target, allow_pickle=False) as a:
                t, features, y = a["t"], a["X"], a["y"]
                correction = float(a["rebase_max_abs_m_s2"])
        else:
            if generated:
                t, x, hz = read_imu(path)
                if len(t) != parent["samples"] or not np.allclose(
                    [t[0], t[-1]], [parent["first_time_s"], parent["last_time_s"]], atol=1e-7):
                    raise ValueError("Augmentation changed parent timing")
                x, correction = rebase_position_effect(x, d, self.augmentation.frozen,
                                                       self.calibration["gyro_bias_deg_s"])
            else:
                t, x, hz = verify_parent(path, parent)
            t, features = extract(t, x, hz, self.settings, self.calibration["gyro_bias_deg_s"])
            y = labels(t, parent, self.settings)
            np.savez_compressed(target, t=t, X=features, y=y, rebase_max_abs_m_s2=correction)
        self.audit.append({"id": identity, "parent": parent["key"], "ai_split": parent["ai_split"],
                           "kind": "augmented" if generated else "original", "path": str(path),
                           "sha256": checksum, "windows": len(t), "scored_windows": int((y>=0).sum()),
                           "normal_windows": int((y==0).sum()), "fall_windows": int((y==1).sum()),
                           "rebase_max_abs_m_s2": correction, "cache_fingerprint": fingerprint})
        return {"id": identity, "parent": parent, "kind": "augmented" if generated else "original",
                "group": row["Group"] if generated else "original", "t": t, "X": features, "y": y}
