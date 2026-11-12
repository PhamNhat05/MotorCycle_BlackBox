# Code guide

## Execution entry points

| Entry point | Inputs | Output |
|---|---|---|
| `RUN_ORIGINAL` | Optional existing original-results path, or `'resume'` | Original results directory |
| `RUN_AUGMENT` | Optional original-results path and augmented-results path/`'resume'` | Augmented results directory |
| `RUN_ALL` | Optional `'resume'` | Structure with `original` and `augmented` paths |

These are the only execution files named `RUN...`. `CHECK_PROJECT` performs
synthetic checks, and `SETUP_PROJECT` registers the source directories.
All other files are named for their specific responsibility.

## Original-stage sequence

1. `load_original_manifest` checks the ten source records and the 7:3 split.
2. `initialize_original_results` creates metadata or validates a continued session.
3. `load_or_estimate_calibration` reuses a verified calibration or estimates it
   from quiet BUILD prefixes only.
4. `process_original_record` reads a complete measured recording, reconstructs
   its motion, evaluates six-axis agreement and exports its outputs.
5. `freeze_original_configuration` locks the shared settings after all seven
   BUILD gates pass and before opening TEST.
6. `write_original_report` produces readable HTML and summary CSVs.
7. `package_original_results` optionally packages original outputs only.

`process_original_records` coordinates these operations without launching the
augmentation stage. The original mathematical kernels are unchanged apart from
function names, comments and formatting.

## Augmentation-stage sequence

1. `validate_original_results` verifies the completed models, quality gates,
   frozen settings and source hashes.
2. `create_augmentation_plan` declares the exact position/bias values for every
   variant before data export.
3. `initialize_augmented_results` stores the plan and experiment identity.
4. `verify_completed_variants` checks CSV, PNG, SVG, HTML, metrics and recipe
   completion markers when continuing an interrupted session.
5. `compute_sensor_variant` calculates the position component and bias offset.
   It also compares the result with direct forward-model queries.
6. `compute_variant_metrics` separates total change, position change, bias and
   baseline reconstruction error on all source samples.
7. `plot_augmented_comparison` exports one six-axis chart as SVG and PNG.
8. `write_variant_report` creates one readable detailed HTML page.
9. `export_augmented_variant` commits the completion marker only after all
   required data, charts and report files have been written.
10. `write_augmented_report` builds parent/global indexes, while
    `collect_variant_metrics` combines all 6,000 metric rows after completion.

`generate_augmented_records` coordinates these steps. Original models are
read-only, one parent is loaded at a time, and every variant is exported separately.

## Important data contracts

| Value | Shape / convention |
|---|---|
| Measured input `A` | N x 7: source seconds, Ax, Ay, Az, Gx, Gy, Gz |
| IMU output `Q.imu` | N x 6: acceleration in m/s^2, gyro in deg/s |
| Model `M.q` | N x 4 Hamilton quaternions, scalar first, active body-to-world |
| Calibration `M.K.bias` | 1 x 6, same units as the sensor output |
| Mounting `M.K.sensor_to_body` | Sensor-to-body rotation matrix |
| `omega_body_rad_s` | N x 3 body-frame angular velocity in rad/s |
| `alpha_body_rad_s2` | N x 3 body-frame angular acceleration in rad/s^2 |
| Position shift | 1 x 3, body-frame metres, Euclidean length <= 0.5 m |
| Bias delta | 1 x 6 constant sensor-axis offset for one full recording |
| `variant.position_component` | N x 6; final three gyro columns are zero |
| `variant.signals` | N x 6 augmented sensor output at unchanged source times |

The nominal measured position is represented by the original model. Translation
augmentation uses the difference between the new and nominal lever arms. It does
not reinterpret a 0.5 m displacement as an absolute X coordinate.

## Reading comments

Public numerical helpers begin with purpose, input and output comments. The
reconstruction and query functions include numbered or named calculation blocks.
Comments identify units, coordinate changes, initialization assumptions and the
distinction between full-record computation and display-only point reduction.

Short variable names such as `M`, `K`, `q`, `omega` and `alpha` retain their
mathematical meanings. Their contracts are listed above and in
`ORIGINAL/docs/MATHEMATICS.md`.

## Report rendering

`report_header` defines one shared high-contrast theme. `chart_report_card`
provides readable-size, fit-width and full-size controls. `write_html_file`
commits complete UTF-8 pages.

SVG is generated through MATLAB's standard `print(...,'-dsvg')` path. PNG is
exported at 220 DPI. The project does not require the newer SVG functionality
of `exportgraphics`.

Official graphics references:

- [MATLAB print](https://www.mathworks.com/help/matlab/ref/print.html)
- [MATLAB exportgraphics](https://www.mathworks.com/help/matlab/ref/exportgraphics.html)

`AUGMENTED/docs/REPORT_PREVIEW.html` reuses the exact HTML theme and display
controls. Its chart is an independently generated Python layout preview from real
source data, clearly distinguished from a native MATLAB result.

## Output integrity

CSV export uses temporary files. A variant completion marker is written after
its CSV, chart formats, HTML report, metrics and parameter JSON succeed.
Continuation verifies all required files and their hashes. An incomplete variant
is regenerated; a committed but modified variant causes a clear error.

Original and augmented settings are separate. Original-stage code snapshots do
not include augmentation-only configuration/source files.

## Function inventory

The following table is generated from the actual source files.

| Source file | Responsibility |
|---|---|
| `AUGMENTED/AUGMENTATION_CONFIG.m` | New experimental augmentation bounds, independent of the ORIGINAL settings. |
| `AUGMENTED/src/evaluation/collect_variant_metrics.m` | Combine 1,000 six-axis tables into 6,000 metric rows. |
| `AUGMENTED/src/evaluation/compute_variant_metrics.m` | Separate total, augmentation, position, bias and baseline changes. |
| `AUGMENTED/src/generation/compute_sensor_variant.m` | Apply one fixed position shift and constant sensor bias. |
| `AUGMENTED/src/io/check_augmentation_disk_space.m` | Estimate space needed for unfinished variants. |
| `AUGMENTED/src/io/export_augmented_variant.m` | Write full CSV, sharp charts and one detailed HTML page. |
| `AUGMENTED/src/io/get_variant_paths.m` | Define all output names for exactly one augmented variant. |
| `AUGMENTED/src/io/verify_completed_variants.m` | Reconcile verified completion markers with recipes. |
| `AUGMENTED/src/planning/create_augmentation_plan.m` | Declare exactly 100 reproducible sensor variants per real recording. |
| `AUGMENTED/src/plotting/plot_augmented_comparison.m` | Draw one variant with readable labels and dark lines. |
| `AUGMENTED/src/reporting/write_variant_report.m` | Create a readable, self-contained page for one variant. |
| `AUGMENTED/src/validation/augmentation_selfcheck.m` | Check counts, bounds and the extracted generation function. |
| `AUGMENTED/src/workflow/generate_augmented_records.m` | Orchestrate 100 full-record variants per original source. |
| `AUGMENTED/src/workflow/initialize_augmented_results.m` | Create run metadata or validate an interrupted run. |
| `AUGMENTED/src/workflow/validate_original_results.m` | Verify the read-only inputs for augmentation. |
| `AUGMENTED/src/workflow/write_augmentation_status.m` | Record the number of completely exported variants. |
| `AUGMENTED/src/workflow/write_augmented_report.m` | Build high-contrast indexes with one page per variant. |
| `CHECK_PROJECT.m` | Validate numerical kernels and augmentation rules on synthetic data. |
| `ORIGINAL/ORIGINAL_CONFIG.m` | Nominal reconstruction only. Augmentation has its own configuration. |
| `ORIGINAL/src/calibration/estimate_calibration.m` | Estimate one shared gyroscope prior using BUILD recordings only. |
| `ORIGINAL/src/conditioning/build_spline_basis.m` | Evaluate a sparse clamped B-spline basis. |
| `ORIGINAL/src/conditioning/condition_signals.m` | Fit overlapping degree-five splines to bias-corrected IMU channels. |
| `ORIGINAL/src/conditioning/differentiate_signal.m` | Differentiate sampled signals with a five-point polynomial stencil. |
| `ORIGINAL/src/evaluation/collect_record_status.m` | Read completion and pass/fail flags without changing result files. |
| `ORIGINAL/src/evaluation/evaluate_reconstruction.m` | Score every original sample against the forward reconstructed IMU. |
| `ORIGINAL/src/io/create_code_manifest.m` | Hash the source files that determine a stage's results. |
| `ORIGINAL/src/io/find_latest_results.m` | Resolve the latest result directory for one independent stage. |
| `ORIGINAL/src/io/hash_file.m` | Compute the SHA-256 of exact file bytes in bounded memory. |
| `ORIGINAL/src/io/read_original_record.m` | Read an unchanged Latin-1, tab-separated source recording. |
| `ORIGINAL/src/io/write_html_file.m` | Atomically write a complete standalone UTF-8 report page. |
| `ORIGINAL/src/io/write_json.m` | Atomically write structured metadata as JSON. |
| `ORIGINAL/src/io/write_numeric_csv.m` | Stream a full numeric matrix to an atomic CSV output. |
| `ORIGINAL/src/plotting/plot_original_comparison.m` | Export a high-contrast six-axis original comparison. |
| `ORIGINAL/src/plotting/select_display_indices.m` | Preserve multi-channel extrema while reducing only chart point counts. |
| `ORIGINAL/src/reconstruction/quaternion_math.m` | Provide scalar-first Hamilton quaternion and mounting operations. |
| `ORIGINAL/src/reconstruction/query_imu.m` | Evaluate continuous motion states and the physical forward IMU model. |
| `ORIGINAL/src/reconstruction/reconstruct_motion.m` | Reconstruct one continuous conditional motion model from all IMU samples. |
| `ORIGINAL/src/reporting/chart_report_card.m` | Display a sharp chart with readable-size and fit-width modes. |
| `ORIGINAL/src/reporting/report_header.m` | Shared high-contrast, offline HTML theme for every report. |
| `ORIGINAL/src/validation/original_selfcheck.m` | Check the original numerical kernels using analytic synthetic cases. |
| `ORIGINAL/src/workflow/export_original_record.m` | Commit the model, full signals/states, charts and quality marker. |
| `ORIGINAL/src/workflow/freeze_original_configuration.m` | Lock the shared settings before opening TEST. |
| `ORIGINAL/src/workflow/initialize_original_results.m` | Create result metadata or validate a resumed run. |
| `ORIGINAL/src/workflow/load_or_estimate_calibration.m` | Reuse a verified prior or estimate it from BUILD. |
| `ORIGINAL/src/workflow/load_original_manifest.m` | Load and verify the declared ten-parent 7:3 split. |
| `ORIGINAL/src/workflow/package_original_results.m` | Package only the original-stage outputs when configured. |
| `ORIGINAL/src/workflow/process_original_record.m` | Reconstruct, evaluate and export one full real record. |
| `ORIGINAL/src/workflow/process_original_records.m` | Orchestrate full-record reconstruction with a fixed 7:3 split. |
| `ORIGINAL/src/workflow/write_original_report.m` | Build readable HTML tables and vector-chart links. |
| `ORIGINAL/src/workflow/write_original_status.m` | Record original-stage progress in a small JSON file. |
| `RUN_ALL.m` | Execute originals first, then augment after all ten original gates pass. |
| `RUN_AUGMENT.m` | Export 100 individual variants for each of ten real recordings. |
| `RUN_ORIGINAL.m` | Process all original recordings without launching augmentation. |
| `SETUP_PROJECT.m` | Register this project's source directories and result folders. |
