# MotorcycleIMULab: ORIGINAL and AUGMENTED

This MATLAB project contains two clearly separated stages. Directory names,
function names, comments, messages, charts and reports are in English.
The ten measured recordings are included without changing their bytes.

## Three execution commands

Extract the ZIP and set MATLAB's Current Folder to `MotorcycleIMULab`.

| Command | Work performed |
|---|---|
| `RUN_ORIGINAL` | Reconstruct and evaluate the ten measured recordings only |
| `RUN_AUGMENT` | Generate variants from a completed original-results session |
| `RUN_ALL` | Process originals, then augment if all ten original gates pass |

For the complete workflow:

```matlab
outputs = RUN_ALL;
```

For separate stages:

```matlab
originalResults = RUN_ORIGINAL;
augmentedResults = RUN_AUGMENT(originalResults);
```

`RUN_AUGMENT` without arguments selects the latest original-results session.
There are **exactly three `.m` files whose names contain `RUN`**. There is no
`RUN_PROJECT` alias. `CHECK_PROJECT` performs synthetic validation only; it does
not reconstruct the real recordings or generate a dataset.

```matlab
checks = CHECK_PROJECT;
```

Target environment: MATLAB R2023a with the standard Java runtime. No additional
MATLAB toolbox is required. SVG uses `print(...,'-dsvg')`, which avoids relying
on the newer SVG support in `exportgraphics`.

## Directory structure

| Directory or file | Responsibility |
|---|---|
| `ORIGINAL/data/build/` | Seven measured BUILD recordings |
| `ORIGINAL/data/test/` | Three measured TEST recordings |
| `ORIGINAL/config/INPUT_MANIFEST.json` | Source keys, labels, timestamps, row counts and checksums |
| `ORIGINAL/ORIGINAL_CONFIG.m` | Original reconstruction and output settings |
| `ORIGINAL/src/calibration/` | Shared BUILD-only gyroscope-prior estimation |
| `ORIGINAL/src/conditioning/` | Spline fitting and numerical differentiation |
| `ORIGINAL/src/reconstruction/` | Quaternion operations, continuous motion and forward IMU |
| `ORIGINAL/src/evaluation/` | Full-record fit metrics and completion flags |
| `ORIGINAL/src/io/` | Source reads, CSV/JSON/HTML writes and checksums |
| `ORIGINAL/src/plotting/` | Original measured-versus-reconstructed charts |
| `ORIGINAL/src/reporting/` | Shared readable HTML styles and chart controls |
| `ORIGINAL/src/workflow/` | Original-stage orchestration, exports and reports |
| `ORIGINAL/src/validation/` | Synthetic numerical checks |
| `ORIGINAL/results/` | Original results only |
| `AUGMENTED/AUGMENTATION_CONFIG.m` | Variant counts, perturbation bounds and display settings |
| `AUGMENTED/src/planning/` | Reproducible variant recipes |
| `AUGMENTED/src/generation/` | Fixed-position and constant-bias sensor equations |
| `AUGMENTED/src/evaluation/` | Per-variant and aggregate error components |
| `AUGMENTED/src/io/` | Variant paths, export transactions and resume verification |
| `AUGMENTED/src/plotting/` | One-variant versus original charts |
| `AUGMENTED/src/reporting/` | Individual detailed HTML pages |
| `AUGMENTED/src/workflow/` | Augmentation orchestration, indexes and status |
| `AUGMENTED/src/validation/` | Counts, limits and generation-helper checks |
| `AUGMENTED/results/` | Augmented results only |

Only source directories are added to MATLAB's search path. Data and generated
results are not added. Shared numerical and reporting utilities remain under
`ORIGINAL/src` and are reused by the augmentation stage.

See `CODE_GUIDE.md` for function inputs, outputs and the execution order.

## Original results

Original processing keeps the full 7 BUILD / 3 TEST protocol. The calibration is
estimated from BUILD prefixes and frozen before TEST. No source rows are removed.
The 24 startup rows containing zeros remain part of the original input and score.

Each session is written to `ORIGINAL/results/RUN_.../`. Open its `REPORT.html`.
Each `records/<parent>/` directory contains:

| Output | Content |
|---|---|
| `MODEL.mat` | Full original reconstruction, used as augmentation input |
| `FULL_SIGNAL_COMPARISON.csv` | Measured and reconstructed six-axis signals |
| `FULL_STATE.csv` | Full motion states and angular quantities |
| `FULL_RECORD_FIT.svg` | Sharp, zoomable vector chart |
| `FULL_RECORD_FIT.png` | High-resolution PNG version |
| `AXIS_FIT.csv` | Six-axis RMSE, MAE, peak error, correlation and fit |
| `QUALITY.json` | Quality gates and final completion marker |

`ALL_AXIS_FIT.csv` contains 60 rows: ten recordings times six axes.
Movie generation has been removed. Motion-state calculation is retained because
it supplies the original IMU model and position-based augmentation.

## Augmented results

Every real recording produces **100 total variants**, divided as follows:

| Group | Variant IDs per parent | Per parent | Across ten parents |
|---|---|---:|---:|
| Bias only | 001-034 | 34 | 340 |
| Position only | 035-067 | 33 | 330 |
| Position and bias | 068-100 | 33 | 330 |
| **Total** | **001-100** | **100** | **1,000** |

All source timestamps and the 1,000 Hz sampling grid are retained. The completed
dataset contains 100,810,700 augmented data rows, excluding CSV headers.

Example output location:

`AUGMENTED/results/RUN_.../records/fall_curve/position_only/variant_035.csv`

Each variant has a full CSV, vector SVG, high-resolution PNG, detailed HTML page,
six-axis metrics, parameter JSON and final completion marker. The SVG and PNG are
two formats of **the same chart**, not different augmented examples.

Open the session's `INDEX.html`, select a parent, then select one detailed report.
`VARIANT_MANIFEST.csv` records 1,000 exact parameter sets. After completion,
`ALL_AXIS_METRICS.csv` contains 6,000 axis-metric rows.

## Readable HTML and charts

- White chart backgrounds, dark text and larger Arial labels.
- HTML body text is 18 px; table text is 17 px with bold headers.
- Main charts use vector SVG, so text and curves remain sharp when enlarged.
- PNG exports use 220 DPI for use outside the browser.
- **Readable size** is the default, with horizontal scrolling for large charts.
- **Fit width** gives a smaller overview when desired.
- **Open full-size chart** opens the SVG directly.
- **Download high-resolution PNG** provides the raster copy.

Each augmented chart contains six rows, one per axis, and three columns:

1. The complete measured parent and exactly one augmented signal.
2. A detailed interval at the original sample rate.
3. Total difference, position effect, bias effect and baseline reconstruction error.

The chart header records the exact XYZ shift, new position and six bias offsets.
The detailed HTML page repeats these parameters in readable text and provides a
full-record error table. Multiple augmented examples are not overlaid together.

An independently generated layout preview is provided in
`AUGMENTED/docs/REPORT_PREVIEW.html`. It illustrates the report theme and display
controls; it is identified as a Python preview rather than a native MATLAB run.

## Augmentation settings

| Parameter | Default |
|---|---|
| Additional acceleration bias | Each sensor axis within +/-10 m/s^2 |
| Additional gyroscope bias | Each sensor axis within +/-0.2 deg/s |
| Position shift | Body-frame vector length at most 0.5 m |
| Nominal sensor position | `[0.05 0 -0.05]` m |
| New position | `nominal_position + position_shift` |
| Sensor orientation | Preserved |
| Bias within a variant | Constant over the full recording |
| Seed | 20261109 |

The previously written value "10 m/s" is interpreted as an acceleration-bias
bound of 10 m/s^2. The gyro bound remains 0.2 deg/s. The 0.5 m limit applies to the
**length of the displacement vector**, not to all three coordinates separately.
For example, shifting X by +0.5 m moves the nominal sensor to `[0.55 0 -0.05]` m.

Signed single-axis probes make parameter effects easy to inspect. Other variants
combine axes using a local seeded MATLAB random stream. MATLAB and NumPy do not
necessarily produce the same random sequence from the same numeric seed.

## Continue interrupted work

The same three execution commands support continuation:

```matlab
RUN_ORIGINAL('resume')
RUN_AUGMENT([], 'resume')
RUN_ALL('resume')
```

An explicit existing directory can also be supplied. `RUN_ALL('resume')` reuses
the latest augmented session only when it belongs to the selected original session.
Create `STOP_AFTER_CURRENT_TASK.txt` inside the active result session to stop at
a record or variant boundary. Remove it before continuing.

Only completed exports with matching identifiers and checksums are reused.
Changing code or settings requires a new affected-stage session. Changes confined
to augmentation settings do not invalidate already completed original results.
Because directory and function names have changed, start fresh sessions with this
version rather than copying results generated by an older project layout.

## Scientific scope and validation

The original calibration, spline, quaternion, integration and forward-IMU equations
are preserved. Augmentation keeps latent motion fixed and applies:

```text
position_effect = (alpha x displacement + omega x (omega x displacement)) * R_BS
augmented_acc   = baseline_acc + position_effect + acceleration_bias_delta
augmented_gyro  = baseline_gyro + gyroscope_bias_delta
```

The source's specific-force and coordinate conventions are documented in
`ORIGINAL/docs/MATHEMATICS.md`. Strong IMU fit is not independent validation of
the world trajectory. The chosen augmentation bounds are experimental settings.
Keep each original parent and all its variants in the same ML split. Descendants
of the three TEST parents are marked as holdout stress tests.

Source preservation, MATLAB syntax, English naming, dependency paths and report
contracts are checked in `ORIGINAL/docs/VALIDATION.json`. The build environment
does not contain MATLAB, so no native MATLAB or graphics execution is claimed.
`CHECK_PROJECT` and the stage quality gates execute in the user's MATLAB session.

The packaged `results` directories are initially empty apart from their README
files. New data and reports are created by the three execution commands.
