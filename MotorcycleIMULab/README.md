# MotorcycleIMULab

A complete MATLAB project for full-record, six-axis IMU-conditioned kinematic reconstruction and sensor augmentation. All project commands, documentation and generated report labels are in English. The ten input recordings are included.

## Run

1. Extract the entire ZIP to a writable local directory. Keep the folder structure.
2. Open MATLAB and select the `MotorcycleIMULab` folder as Current Folder.
3. Run:

```matlab
runDirectory = RUN_PROJECT;
```

Target: MATLAB R2023a or newer, desktop graphics and a JVM. The implementation uses base MATLAB; Optimization, Navigation, Spline and System Identification Toolboxes are not required. Windows/macOS MPEG-4 export falls back to Motion JPEG AVI when necessary. A working graphics renderer is required for plots/videos. Python is not required.

The command runs synthetic self-checks, verifies input checksums, estimates a shared gyro prior from BUILD prefixes, reconstructs all seven complete BUILD recordings, freezes the common configuration after the BUILD gate, reconstructs three complete TEST recordings without retuning, and then generates sensor variants if all ten records pass. Videos are exported for each completed record, including failed-fit BUILD records. An unsuccessful BUILD gate leaves TEST unopened and augmentation blocked.

There is no 30-minute timer, automatic pause or automatic parameter sweep. Processing and exports continue until completion, an explicit stop, an error or insufficient disk space. Runtime depends on CPU, MATLAB sparse solvers, graphics and disk speed; no three/four-hour guarantee is made.

## Read the results

Open the newest `results/RUN_*/REPORT.html`. It contains six-axis fit tables, full-record overlays and video links. `ALL_AXIS_FIT.csv` contains all 60 axis rows when all ten records have completed. `FULL_SIGNAL_COMPARISON.csv` retains every original timestamp and measured/reconstructed sample. `FULL_STATE.csv` and `MODEL.mat` retain the state representation used by the forward sensor model and videos.

The data include 1,008,107 samples across ten recordings, approximately 48–149 seconds each. All samples, including 24 leading zero rows per recording, are retained and scored. Processing uses overlapping numerical blocks but integrates one continuous state chain across the complete record.

## Scientific scope

This is conditional kinematic reconstruction, not a forward dynamics/contact solver. Each TEST record's own six IMU channels are reconstruction inputs. The held-out test checks whether the same shared settings reproduce unseen recordings; it is not a blind prediction of TEST signals.

IMU fit is a forward roundtrip through an IMU-driven state model. A very high fit can occur by construction. It does not establish absolute position, road tracking, rider biomechanics, true physical bias, or useful classifier improvement. World position may drift strongly without independent velocity/position observations. Video uses a body-centered moving camera and an integrated-path inset; it does not add a road constraint or hide numerical drift in the state files.

`docs/DATA_PROVENANCE.md` identifies the published dataset and its 2020 Ay correction. The exact supplied CSV edition has not been matched byte-for-byte against the corrected publisher ZIP. The project preserves those bytes and reports that uncertainty. Do not describe them as verified corrected publisher data until that comparison is completed.

## Continue or export

```matlab
RESUME_PROJECT(runDirectory)                  % Resume saved tasks, same code/settings
EXPORT_VIDEOS(runDirectory)                   % Retry missing/failed videos, no refitting
EXPORT_AUGMENTED_DATA(runDirectory)           % Resume default full CSV materialization
EXPORT_AUGMENTED_DATA(runDirectory,'compact') % Recipes only; not 700 materialized CSVs
T = LOAD_VARIANT(runDirectory,'fall_curve',1); % Reconstruct one full variant on demand
PREVIEW_VARIANT(runDirectory,'fall_curve',1)  % Full-record variant video
RUN_SELF_CHECKS                               % Synthetic MATLAB mathematics checks
```

To request a clean stop, create an empty `STOP_AFTER_CURRENT_TASK.txt` in the run directory. Remove it before resuming. A stop takes effect at the next record/variant boundary; video rendering and an individual reconstruction finish their current task. Ctrl+C stops immediately; resume repeats an incomplete record/video/variant and reuses completed tasks. There are no within-record recovery checkpoints.

The default augmentation creates 100 variants for each of seven BUILD parents: 700 full CSV files, 75,768,100 rows. Expect roughly 10–15 GB for these CSVs plus nominal state files and videos; the conservative disk guard reserves additional space. Each variant has a JSON definition, parent hashes and a completion checksum. TEST parents never generate training variants. The upload report ZIP excludes the bulk variant CSVs but includes nominal full outputs, videos, definitions and checks. Keep the complete local run directory for the actual generated CSV dataset.

Read [OBJECTIVES.md](OBJECTIVES.md), [docs/WORKFLOW.md](docs/WORKFLOW.md), [docs/MATHEMATICS.md](docs/MATHEMATICS.md), and [docs/REFERENCES.md](docs/REFERENCES.md) before interpreting a PASS result. Host checks are documented in `docs/HOST_QA.json`; actual MATLAB execution and the measured-data 7:3 result must be obtained on the target machine.
