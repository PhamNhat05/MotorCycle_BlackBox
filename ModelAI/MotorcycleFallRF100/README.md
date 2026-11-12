# MotorcycleFallRF100

Python 3.11 command-line AI project for the supplied MotorcycleIMULab ORIGINAL
and AUGMENTED data. All classifiers in this project are **Random Forests with
exactly 100 trees**, maximum depth 8 and 24 input features. No epoch parameter is
used. The ten original measured CSVs are included byte-for-byte. MATLAB is not
required for AI training or prediction; MATLAB generates the optional variants.

## Start on Windows

Extract this ZIP to a writable folder. Install 64-bit Python 3.11.

1. Open `INSTALL_WINDOWS.bat` once; Internet is needed to install dependencies.
2. Finish `RUN_ORIGINAL` and `RUN_AUGMENT` in your separate MotorcycleIMULab
   MATLAB project if you want augmented training.
3. Open `RUN_TRAIN.bat`. Enter the MotorcycleIMULab root folder, without
   surrounding quotes. The script resolves `AUGMENTED/results/LATEST_RUN.txt`.
   Alternatively enter the exact `AUGMENTED/results/RUN_...` directory.
4. Open `results/RUN_.../REPORT.html` when the console prints `COMPLETE`.
5. Use `RUN_PREDICT.bat` for a new original-format or generated-format CSV.

Pressing Enter at the augmentation prompt explicitly runs measured-only training.
An invalid or incomplete supplied augmentation directory raises an error; it
does not silently fall back to measured-only training. The uploaded MATLAB ZIP
contains generation code, not the 1,000 generated CSVs. No generated dataset is
invented or counted as already available.

`RUN_CHECK.bat` executes meaningful synthetic checks plus raw-data integrity
checks. These are the three RUN launchers: training, prediction, checks.
Names, code comments and generated reports are in English.

An optional complete importer/pipeline check creates 1,000 miniature synthetic
CSV variants in a temporary directory, checks 600/200/200 isolation, rejects a
tampered CSV and incomplete exports, fits RF100, writes reports, then cleans up:

```bat
.venv\Scripts\python.exe tests\augmentation_fixture_check.py
```

This is a software fixture, not measured motorcycle classification performance.

## Equivalent Python commands

```bat
py -3.11 -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Project\MotorcycleIMULab"
```

If you moved the augmented result outside its source project, provide its
matching original result as well:

```bat
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Saved\Augmented_RUN" --original-run "D:\Saved\Original_RUN"
```

Without augmentation:

```bat
.venv\Scripts\python.exe train.py
```

Incomplete exported datasets are accepted only with explicit `--allow-partial`.
Counts then reflect actual completed CSV/JSON pairs. A complete standard run
requires 100 variants per parent: 34 bias-only, 33 position-only, 33 combined.

## Exact AI split

| AI split | Original parents | Falls / nonfalls | Expected variants | Available files with complete augmentation |
|---|---:|---:|---:|---:|
| TRAIN | 6 | 2 / 4 | 600 | 606 |
| VALIDATION | 2 | 1 / 1 | 200 | 202 |
| TEST | 2 | 1 / 1 | 200 | 202 |

TRAIN: `fall_curve`, `fall_leaning`, `acceleration_straight`,
`harsh_braking_straight`, `fall_like_1`, `fall_like_2`.

VALIDATION: `fall_roundabout`, `acceleration_curve`.

TEST: `fall_slippery_straight`, `fall_like_3`.

The simulation's 7 BUILD / 3 TEST grouping remains provenance metadata. The AI
6/2/2 grouping is explicit in `config/parents.json`; no random window split is
performed. Every descendant follows its original parent.

Six TRAIN originals and their 600 descendants fit the mixed model. Only the two
real VALIDATION files select the threshold and candidate. The 200 validation
descendants and 200 test descendants are evaluated after model selection as
separate sensor-robustness checks. They do not enter fitting or model selection.
The two real TEST files provide the primary held-out-file result.

## What is trained

With augmentation, two controlled candidates are fitted:

- `real_only__rf100`: six measured TRAIN files.
- `mixed__rf100`: the same six measured files plus their completed descendants.

Both use identical 100-tree settings, depth 8, minimum leaf size 1, bootstrap,
sqrt feature subsampling, seed 42 and 24 features. TRAIN weights balance class,
parent, measured/synthetic category and descendant recording. Every window of a
long file is not treated as an equally independent physical experiment.

Real VALIDATION selects in this order: contact-associated event recall, F2,
fewer false alarm events, shorter nonnegative contact delay. Exact condition
ties prefer mixed. Threshold ties prefer the higher threshold. The choice is
hashed and frozen before numeric real TEST streams are opened. TEST never
reselects/refits a model. The final selected model is always RF100.

## Compatible augmentation export

Expected files from your current MATLAB project:

```text
AUGMENTED/results/RUN_.../
    VARIANT_MANIFEST.csv
    ORIGINAL_RUN.json
    records/<parent>/<group>/variant_001.csv
    records/<parent>/<group>/variant_001.json
    records/<parent>/<group>/variant_001.complete.json
ORIGINAL/results/<matching-run>/FROZEN_CONFIGURATION.json
```

CSV headers: `Time_s,Ax_m_s2,Ay_m_s2,Az_m_s2,Gx_deg_s,Gy_deg_s,Gz_deg_s`.
The importer verifies completion markers, CSV/definition hashes, parent model
hashes, frozen configuration, source timing, group identity and perturbation
bounds. Paths and file counts come from the manifest, not from a broad CSV glob.

**Shared-calibration handling:** the simulator estimates a gyro prior from
seven BUILD parents, one of which is AI VALIDATION. The importer analytically
replaces the old gyro-prior contribution to the centripetal position-shift term
with a prior estimated only from the six AI TRAIN parents. Constant prior change
does not change angular acceleration. Exported CSV bytes remain unchanged.
This sensor-level operation is logged in `AUGMENTATION_REBASE_INFO.json` and
`DATASET_AUDIT.csv`. See `docs/METHOD.md` for scope and equations.

## Output files

- `REPORT.html`: readable white-background report with SVG charts and tables.
- `DATA_SPLIT.csv`, `SPLIT_SUMMARY.csv`: expected AND actual original/augmented counts.
- `DATASET_AUDIT.csv`: source hashes, parent groups, feature-window counts, rebase correction.
- `VALIDATION_CANDIDATES.csv`, `VALIDATION_THRESHOLD_SEARCH.csv`: selection evidence.
- `MODEL_SELECTION_FROZEN.json` and `.sha256`: decision before numeric TEST reads.
- `TEST_COMPARISON_PREDECLARED_MODELS.csv`: fixed-candidate comparison without reselection.
- `EVALUATION_SUMMARY.csv`, `CLASS_METRICS.csv`, `PER_RECORD_METRICS.csv`.
- Confusion matrices for original TRAIN, real VALIDATION, real TEST, augmented
  TRAIN, held-out augmentation and the all-data fitted diagnostic when available.
- `predictions/original/`: every full-window prediction for all ten originals.
- `predictions/augmented/`: every evaluated descendant's timeline.
- `ORIGINALS_SEQUENTIAL_TIMELINE.csv`: ten independent sessions placed on a common
  display timeline. Filter/buffer/alarm state resets at file boundaries; joining
  separate recordings is not a real uninterrupted motorcycle journey.
- `best_model.joblib`, `BEST_MODEL_INFO.json`, `models/`: fitted RF100 bundles.
- `feature_cache/`, `RUN_LOG.txt`, `STAGES.jsonl`: verified reuse and stage order.

TRAIN and all-data scores include fitted examples. They must not be described
as generalization accuracy. Only one independent recorded fall exists in real
TEST; 100 variants of it do not become 100 independent crashes.

## Full-file and live inference

Acceleration input is m/s^2; gyro input is deg/s. Times are in seconds and must
be uniform and increasing. Source frequency must be an integer multiple of
100 Hz. The supplied tab-separated Latin-1 raw CSVs and generated CSVs are both
supported. Named `time,Ax,Ay,Az,Gx,Gy,Gz` and Rx/Ry/Rz aliases are also accepted.

```bat
.venv\Scripts\python.exe predict.py --csv "D:\Signals\new.csv"
.venv\Scripts\python.exe predict.py --csv "D:\Signals\new.csv" --stream
```

`--stream` replays causal sample-by-sample inference. Default full-file inference
uses the same causal filter, decimation phase, past-only windows and features.
The `StreamingPredictor` API in `rf100/stream.py` accepts successive samples or
blocks from a live acquisition source. It produces a fall score/label/alarm
after the initial full window, then every 0.5 s. No ESP32 latency or memory
benchmark is claimed. This package targets laptop training/testing.

To supply an explicit trained model:

```bat
.venv\Scripts\python.exe predict.py --model "results\RUN_...\best_model.joblib" --csv "D:\Signals\new.csv" --out "new_predictions"
```

## Stop and resume

Ctrl+C stops processing. Repeat with the same result path:

```bat
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Project\MotorcycleIMULab" --out "results\RUN_..." --resume
```

Verified feature caches are reused; unfinished model fitting starts again.
Changes to source bytes, source label metadata, generator manifest, settings or
feature code invalidate reuse or require a new run. There are no timed pauses.

See `docs/METHOD.md`, `docs/FEATURES.md`, `docs/REFERENCES.md` and
`docs/CODE_GUIDE.md`. `example_results/` contains an actual measured-only run
on the supplied ten originals; it is not an augmented-training result. Native
Windows launchers and the external MATLAB generator were not executed on the
Linux validation host. Corrected publisher-data edition identity remains
unverified; see the included original provenance/license documents.
