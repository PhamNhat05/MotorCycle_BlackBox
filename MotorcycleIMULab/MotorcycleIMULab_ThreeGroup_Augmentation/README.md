# MotorcycleIMULab: three sensor augmentation groups

This standalone MATLAB add-on reads an existing completed MotorcycleIMULab result folder. It does not rerun reconstruction, alter the original project code, change its frozen configuration, or train an AI model. It creates new full-record sensor variants from all ten saved parent models, as requested.

The attached result archive could not be opened in the preparation environment. No real-result PASS or completed generation is claimed. The exporter verifies all ten full-record quality gates and frozen configuration locally before writing variants.

## Run

1. Extract this add-on to a separate folder. Open that folder in MATLAB R2023a or newer.
2. Keep the existing completed result folder, including `RUN_STATE.mat`, `FROZEN_CONFIGURATION.json`, its `.sha256` and all ten `records/KEY/MODEL.mat` / `QUALITY.json` files.
3. Run:

```matlab
outputDirectory = RUN_THREE_GROUP_AUGMENTATION;
```

Select the existing `RUN_...` folder when prompted. An explicit path is also supported:

```matlab
outputDirectory = RUN_THREE_GROUP_AUGMENTATION('C:\MyProject\results\RUN_20261101_192924_866');
```

Output is written to `augmentation_three_groups` inside that result folder. No edit to the original project is required. Existing `augmentation/` files from the earlier exporter are separate and are not counted as part of this new dataset.

## Default allocation

| Group folder | What changes | Per parent | Across ten parents |
|---|---|---:|---:|
| bias_only | Constant accelerometer/gyro bias; nominal sensor position | 34 | 340 |
| position_only | Fixed body-frame sensor position; nominal bias | 33 | 330 |
| bias_and_position | Both constant bias and fixed sensor position | 33 | 330 |
| Total | | 100 | 1000 |

These are 1000 additional synthetic full-record CSVs, plus ten numerical copies of measured parent recordings. They are not 1000 independent falls/rides. If 100 variants per group per parent are wanted instead, set all three counts to 100 in THREE_GROUP_CONFIG; that produces 3000 variants. A settings change requires a fresh output directory.

Bounds per axis are accelerometer bias ±0.1 m/s^2, gyro bias ±0.2 deg/s and sensor translation ±0.02 m in body coordinates. Bias/translation are drawn once and remain constant for each entire variant. The requested bounds must not exceed the original frozen experiment's bounds. These are declared experimental ranges, not confirmed hardware tolerances or empirically proven realism limits.

The original latent motion stays fixed. A translated IMU changes tangential/centripetal acceleration but not gyro for a rigid body with unchanged mounting rotation. The exporter computes those terms from saved angular velocity/acceleration and compares sampled outputs with the full forward model. No new crash/contact event is simulated.

## Outputs and recovery

- `bias_only/KEY/variant_NNNN.csv`, `position_only/...`, `bias_and_position/...`: all source timestamps and six IMU channels, no event cropping.
- Matching `.json`: group, parent hash, exact bias/position, original split, record/event metadata and limitations.
- Matching `.csv.complete.json`: output checksum, row count, finite-output check, forward consistency, maxima/change diagnostics.
- `real_measured/build` and `real_measured/test`: numerical copies of original measured channels, not byte-identical copies of the original header/delimiters.
- `VARIANT_MANIFEST.csv`: all requested variants and completion status.
- `AI_SPLIT_PROPOSAL.csv`, `AI_PROTOCOL_STATUS.json`: parent grouping and explicit AI-protocol limitations.
- `STATUS.json`, `AUGMENTATION_STATE.mat`: progress and saved settings/source fingerprints.

Default full export covers 100,810,700 synthetic rows. A conservative disk estimate is roughly 15–20 GB including a reserve; available space is checked before CSV export. Compact recipe mode is available in THREE_GROUP_CONFIG, but recipes are not reported as materialized CSVs. Conversion to a different mode uses a new output directory because settings are immutable within a run.

```matlab
RESUME_THREE_GROUP_AUGMENTATION(outputDirectory)
T = LOAD_THREE_GROUP_VARIANT(outputDirectory,'position_only','fall_curve',1);
RUN_THREE_GROUP_SELF_CHECKS
```

Create `STOP_AFTER_CURRENT_FILE.txt` in the output folder for a stop at a file boundary, then remove it before resuming. Ctrl+C may leave a `.partial` file; incomplete files are regenerated. Completed CSVs are checksum-verified on resume. No 30-minute pause exists.

Read `docs/AI_DATA_PROTOCOL.md` before using these files to train or evaluate AI. A good IMU reconstruction does not certify independent 3D motion or the data edition. The original Ay correction/edition uncertainty is inherited, not resolved by augmentation. Native MATLAB execution is still required; preparation checks are in `docs/HOST_QA.json`.
