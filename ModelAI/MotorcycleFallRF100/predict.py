"""Predict one or more full measured recordings using a frozen RF100 bundle."""
from pathlib import Path
import argparse
import time
import joblib
import numpy as np
import pandas as pd
from rf100.io import read_imu, sha256, write_json
from rf100.features import extract, FEATURE_NAMES
from rf100.metrics import alarms
from rf100.stream import StreamingPredictor


def main():
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, help="Defaults to results/LATEST_RUN.txt/best_model.joblib")
    parser.add_argument("--csv", type=Path, nargs="+", required=True)
    parser.add_argument("--out", type=Path, default=root / "new_predictions")
    parser.add_argument("--stream", action="store_true", help="Replay sample by sample with persistent causal state")
    args = parser.parse_args()
    model_path = args.model
    if model_path is None:
        pointer = root / "results/LATEST_RUN.txt"
        if not pointer.is_file(): parser.error("Train first or supply --model")
        run_path = Path(pointer.read_text(encoding="utf-8").strip())
        if not run_path.is_absolute(): run_path = root / run_path
        model_path = run_path / "best_model.joblib"
    bundle = joblib.load(model_path)
    if bundle["feature_names"] != FEATURE_NAMES or len(bundle["model"].estimators_) != 100:
        raise ValueError("Expected this project's 24-feature RF100 model bundle")
    args.out.mkdir(parents=True, exist_ok=True)
    all_rows = []; audit = []; offset = 0.0
    for index, path in enumerate(args.csv, 1):
        t, x, hz = read_imu(path); start = time.perf_counter()
        if args.stream:
            frame = pd.DataFrame(StreamingPredictor(bundle, hz).push_block(t, x))
        else:
            ends, features = extract(t, x, hz, bundle["settings"], bundle["calibration"]["gyro_bias_deg_s"])
            if not len(features): raise ValueError(f"Recording shorter than a full window: {path}")
            model = bundle["model"]
            p = model.predict_proba(features)[:, list(model.classes_).index(1)]
            high = p >= bundle["threshold"]
            frame = pd.DataFrame({"time_s": ends, "probability_fall": p,
                "predicted_fall": high.astype(int),
                "alarm": alarms(ends, high, bundle["settings"]["alarm_cooldown_s"]).astype(int)})
        if frame.empty: raise ValueError(f"Recording shorter than a full window: {path}")
        elapsed = time.perf_counter()-start
        frame.insert(0, "source_file", path.name)
        frame.insert(1, "session_time_s", offset+frame.time_s-t[0])
        frame.insert(2, "independent_session_reset", [True]+[False]*(len(frame)-1))
        frame.to_csv(args.out / f"{index:02d}_{path.stem}_predictions.csv", index=False)
        all_rows.append(frame)
        audit.append({"source": str(path.resolve()), "sha256": sha256(path), "source_hz": hz,
                      "source_samples": len(t), "predicted_windows": len(frame),
                      "host_processing_seconds": elapsed, "sample_replay": args.stream})
        offset += t[-1]-t[0]+1.0
        print(f"{path.name}: {len(frame)} windows, {int(frame.alarm.sum())} alarms", flush=True)
    pd.concat(all_rows, ignore_index=True).to_csv(args.out / "SEQUENTIAL_PREDICTIONS.csv", index=False)
    write_json(args.out / "PREDICTION_INFO.json", {"model_sha256": sha256(model_path),
        "threshold": bundle["threshold"], "files": audit,
        "boundary_policy": "Independent sessions reset filter, ring buffer and alarm cooldown; timeline is a visualization join",
        "ground_truth_provided": False})
    print(f"Saved predictions: {args.out.resolve()}")


if __name__ == "__main__": main()
