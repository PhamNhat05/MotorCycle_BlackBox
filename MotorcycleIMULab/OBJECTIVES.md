# Objectives and acceptance steps

## Objective

Build a reproducible MATLAB pipeline that reconstructs the six measured IMU channels over each complete recording, evaluates a fixed shared configuration with a declared 7:3 record split, and generates explicitly labeled sensor perturbations after the conditional reconstruction gate passes.

The project must retain raw data, record assumptions, identify equations through primary scientific/technical sources, and distinguish numerical fit from independently validated physical motion.

## Deliverables

- Ten immutable, English-named input CSV files and an original-name/SHA-256 manifest.
- Seven complete BUILD reconstructions and three conditional TEST reconstructions, subject to the BUILD gate.
- A shared configuration frozen before TEST data are opened for reconstruction.
- Full-record measured/reconstructed CSVs, state CSVs, saved continuous models, and all six per-axis metrics for every processed file.
- Full-time-span motorcycle/rider/IMU simulation videos and integrated-path drift diagnostics.
- A readable HTML report, numerical CSV summaries, run log and machine-readable status/checkpoints.
- If all ten conditional gates pass, 700 BUILD-only full-record sensor variants with exact bias/position definitions, hashes and checks.
- A formula-to-code/source map, dataset provenance, limitations and reproducibility instructions.

## Ordered steps

1. Verify exact raw input checksums, 1000 Hz timestamps, row counts and disjoint 7:3 split. Retain all startup/post-event rows.
2. Run synthetic checks of quaternion conventions, basis evaluation, signal coverage and off-center acceleration through independent position differentiation.
3. From the seven BUILD files only, identify quiet-prefix candidates and estimate one common gyro bias prior. Fix accelerometer bias, sensor mounting and lever-arm assumptions before reconstruction.
4. Apply one declared wideband conditioning rule to all six channels of all seven full BUILD files. Integrate one uninterrupted state per record, derive forward IMU and score every raw sample.
5. If all BUILD gates pass, freeze the entire common scientific configuration and shared calibration, write SHA-256 and open TEST. If they fail, report failure without searching TEST or changing thresholds.
6. Reconstruct all three complete TEST recordings with that frozen common configuration. Each record still supplies its own IMU and initialization prefix; this conditional use is reported explicitly.
7. Report the fit of each individual axis, including NRMSE fit percentage, RMSE, MAE, maximum error, Pearson correlation, thresholds and row/time coverage. Keep world drift diagnostics separate from fit scores.
8. Export a video covering the full source-time interval of each processed record. Show a rigid rider illustration, nominal sensor point and the unvalidated integrated path.
9. If all 7+3 pass, freeze each BUILD latent motion and synthesize sensor output with a constant six-axis bias perturbation and a fixed body-frame sensor translation. Do not rerun inverse reconstruction per variant.
10. Materialize every requested variant, save provenance/checks, and package nominal results plus compact variant definitions for review. Report pending disk/video/export work honestly.

## Fixed conditional reconstruction gate

For each axis, RMSE must not exceed the larger of the fixed floor and 5% of that full measured channel's range. Floors are 0.35 m/s^2 for acceleration and 1 deg/s for gyro. Pearson r must be at least 0.95 when measured standard deviation is at least 0.1 m/s^2 or 0.5 deg/s, respectively. The range-based rule uses each record to evaluate error; it does not tune the forward model. These acceptance limits are engineering choices, not published sensor accuracy specifications.

All states/outputs must be finite, quaternion norm error must be at most 1e-9, forward roundtrip numerical error must be at most 1e-6, and every original sample must be scored. Constant channels report undefined NRMSE/correlation where appropriate instead of an invented 100% score.

PASS establishes these numerical conditions only. It does not certify correct absolute 3D motion, correct publisher data edition, independent bias identification, plausible road contact, or downstream detection improvement. The data-edition check and independent downstream evaluation remain separate work before scientific claims.

## Sensor augmentation assumptions

Default per-axis perturbations are accelerometer bias ±0.1 m/s^2, gyro bias ±0.2 deg/s, and sensor translation ±0.02 m in body coordinates. They are a declared small-perturbation experiment, not universally allowable hardware tolerances. The original motion, mounting rotation, timestamps, event annotations and record identity stay fixed. A translated sensor changes tangential and centripetal acceleration, while a constant gyro bias changes the reported gyro signal. No new crash/contact process is claimed.

All descendants of a parent recording belong in that parent's training partition. Do not split overlapping windows or variants of the same parent across training and test. No classifier is trained by this project.
