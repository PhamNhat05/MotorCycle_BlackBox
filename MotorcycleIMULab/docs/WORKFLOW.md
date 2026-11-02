# Execution and configuration freezing

## Record allocation

| BUILD: configuration and reconstruction | TEST: fixed-configuration conditional reconstruction |
|---|---|
| fall_curve | fall_slippery_straight |
| fall_roundabout | acceleration_curve |
| fall_leaning | fall_like_3 |
| acceleration_straight | |
| harsh_braking_straight | |
| fall_like_1 | |
| fall_like_2 | |

This is a manually declared record split, not a random sample split or a subject-independent experiment. Only one held-out fall recording is available. Do not infer a population generalization guarantee from three TEST files.

## What is shared and what is per-record

| Quantity | Source | Frozen across TEST? |
|---|---|---|
| Gyro bias prior | Median quiet-window means within BUILD, then median across qualifying BUILD files | Yes |
| Accelerometer bias | Fixed zero prior | Yes |
| Sensor-to-body rotation and nominal sensor position | Declared geometric assumptions | Yes |
| Spline settings and quality rules | PROJECT_CONFIG before processing | Yes |
| Per-record attitude, motion and state | That record's six IMU channels, including TEST | Reconstructed separately using the same rule |
| Initial tilt | That record's fixed 0.5–2 s prefix, assumed approximately gravity dominated | Same rule, different measured prefix |
| Initial yaw, body position and velocity | Fixed priors | Yes |
| Augmentation bounds and seed | PROJECT_CONFIG | Yes |

The common calibration is estimated before BUILD reconstruction and does not adapt per file. No parameter optimizer searches for the best combination. After the seven BUILD gates pass, `FROZEN_CONFIGURATION.json` and its SHA-256 are written before TEST reconstruction. The saved candidate calibration has its own checksum. Resume verifies source code, declared settings, raw checksums and frozen configuration.

## Full-file processing

Every input has a continuous 1 ms time grid. The fitter uses 2 s numerical blocks with 0.25 s overlap and quintic splines on a 2 ms knot grid. Cosine weights blend every overlapping sample. These blocks bound memory and solve size; they do not crop events, drop prefixes, insert independent trajectories or reset state.

After conditioning, one quaternion and translational chain is integrated over the complete recording. Outputs retain the original absolute source timestamps; only numerical block coordinates use local time. Every sample is used by metrics, including leading all-zero rows, pre-fall motion, impact and post-fall handling.

The complete world trajectory can drift severely. The code does not force endpoints, clip height, impose a road or subtract an unexplained trend. Body-centered video keeps geometry readable while the path inset and state CSV expose the actual integrated path. Rider geometry is rigidly attached for illustration; separation and articulated body motion are not measured by a motorcycle-mounted IMU.

## Checkpoints and status

`QUALITY.json` is the completion marker of a record and is written after the model, numerical outputs and plot. `VIDEO_STATUS.json` marks complete video export; a partial video is rerendered. A variant CSV is complete only with its `.complete.json` sidecar. `.partial` files are never completion markers.

`RESUME_PROJECT` uses saved settings, rejects changed code/settings/inputs and reuses completed tasks. A failed gate is a completed scientific result, not a task that resume automatically retunes. Start a separate run to change scientific settings, and disclose any TEST-informed changes as a new exploratory experiment.

`STOP_AFTER_CURRENT_TASK.txt` requests a stop at record/variant boundaries. An interrupted reconstruction restarts its record. An interrupted video restarts its video. An interrupted variant restarts its CSV. There is no fixed execution-time limit.

## Output map

| Path inside a run | Contents |
|---|---|
| REPORT.html | Main report: full-record fits, tables, links and limitations |
| ALL_AXIS_FIT.csv | Six axis rows per completed recording; 60 after all ten |
| RECORD_SUMMARY.csv | Split, gate, scored rows, timestamps and drift diagnostics |
| FROZEN_CONFIGURATION.json / .sha256 | Shared configuration written before TEST |
| records/KEY/MODEL.mat | Continuous state representation, measured/conditioned IMU, calibration and provenance |
| records/KEY/FULL_SIGNAL_COMPARISON.csv | All raw timestamps and all six measured/reconstructed channels |
| records/KEY/FULL_STATE.csv | Full state samples, scalar-first quaternions, angular velocity and acceleration |
| records/KEY/FULL_RECORD_FIT.png | Full-record min/max-envelope overlays |
| records/KEY/FULL_RECORD_SIMULATION.mp4 or .avi | Full source-time simulation, default 2x playback at 10 fps |
| augmentation/VARIANT_MANIFEST.csv | Parent keys, perturbations, sample counts, materialization status |
| augmentation/KEY/variant_NNNN.json | Exact definition and parent/frozen hashes |
| augmentation/KEY/variant_NNNN.csv | All source-time samples of the requested variant |
| augmentation/KEY/variant_NNNN.csv.complete.json | Output hash and forward-consistency result |
| augmentation/STATUS.json | Complete, compact-only, disk-pending or stopped status |
| RUN_STATE.mat / RUN_LOG.txt / STATUS.json | Saved settings, execution log and workflow status |

`RUN_*_REPORT.zip` is written beside the run directory. It contains nominal full outputs, video and compact augmentation provenance. Large variant CSVs remain locally and are excluded to keep the review upload manageable. Depending on video codec and compression, even the report ZIP can be large.
