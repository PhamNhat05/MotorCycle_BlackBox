# Method and evaluation protocol

## 1. Inputs and target

Each row is source time in seconds followed by Ax, Ay, Az in m/s^2 and Gx, Gy,
Gz in deg/s. Gyro channels measure angular velocity, not Euler angles. The
included data contain 10 independent recordings, 4 with a recorded fall and 6
without a fall. Their exact bytes, timing and contacts are in config/parents.json.

This task is contact-associated fall classification. It does not establish
instability onset, validated pre-crash airbag timing or a physical 3D trajectory.
The ten raw recordings have also been inspected in earlier project iterations;
the present file split is procedural separation, not a pristine new dataset.

## 2. Group split and calibration

Split original parents 6 TRAIN / 2 VALIDATION / 2 TEST before computing fitted
statistics. All descendants and overlapping windows inherit the parent split.
The simulator's 7 BUILD / 3 TEST labels are retained independently as provenance.

Estimate one gyro prior from TRAIN only. Scan 0.5-second segments in [0.5, 5) s.
Accept a segment if maximum axis gyro sample STD <= 0.6 deg/s, maximum absolute
axis gyro mean <= 5 deg/s, maximum axis acceleration sample STD <= 0.3 m/s^2,
and norm(mean acceleration) differs from 9.81 by <= 1.5 m/s^2. Take a median of
accepted segment means per parent, then median across qualifying parents.
At least two TRAIN parents must qualify. Stationarity is not independently
verified. Accelerometer bias remains a declared zero prior.

## 3. Augmentation compatibility and analytic rebase

The new MATLAB generator exports 34 bias-only, 33 position-only and 33 combined
variants per parent. Bounds are per-axis +/-10 m/s^2 acceleration bias,
+/-0.2 deg/s gyro bias, and body-frame displacement norm <= 0.5 m. Timestamps,
mounting rotation and latent motion are preserved. These are experimental sensor
perturbations, not verified hardware error distributions or new crash motions.

The original MATLAB gyro prior is estimated using seven BUILD parents, including
one AI VALIDATION parent. Importing the position variants verbatim would carry
that common fitted statistic into AI TRAIN. The fixed-position equation is

    delta_a = [alpha x dr + omega x (omega x dr)] R_BS

Let b_old be the original common gyro prior, b_train the six-TRAIN estimate,
db_g the added variant gyro bias, g_v the exported variant gyro, and R_BS the
rotation used by the exporter. In the row-vector convention:

    omega_old = radians(g_v - db_g - b_old) R_BS^T
    omega_train = omega_old + radians(b_old - b_train) R_BS^T

A constant prior shift has zero derivative, so alpha is unchanged. Update the
exported acceleration by

    correction = [omega_train x (omega_train x dr)
                  - omega_old x (omega_old x dr)] R_BS

This exactly replaces the prior-dependent centripetal contribution while
retaining the tangential contribution, fixed nominal conditioned signals and
explicit bias perturbations. It applies to the supplied schema-2 conditional
generator with fixed mounting and constant common bias. It is not a rerun of
the latent quaternion/world-trajectory reconstruction and makes no claim about
its unique physical interpretation. Raw exported files are never overwritten.
Synthetic algebra checks exercise nonidentity mounting, nonzero alpha and bias.

Importer checks include parent/group identities, source grid and duration,
completion markers, CSV/JSON hashes, parent-model/frozen-configuration hashes,
and experimental bounds. An incomplete dataset is rejected by default.

## 4. Causal signal processing

Subtract the frozen TRAIN gyro prior from every original or augmented record.
Apply a fourth-order Butterworth low-pass at 25 Hz using second-order sections
and causal scipy.signal.sosfilt. Initial filter state corresponds to the first
sample held constant. Do not use filtfilt, future samples or per-window resets.

Decimate by source_hz / 100, retaining the source-first-sample phase. Source
frequency must be an integer multiple of 100 Hz. Preserve the source timestamp
grid; do not align to contact or remove startup zero rows.

At 100 Hz, each window contains 200 samples x 6 channels, and the hop is 50
samples. Features depend on the current and previous 199 decimated samples.
The first output occurs at source_start + 1.99 s, then every 0.5 s. An existing
stream does not wait a fresh two seconds for every prediction. Filter delay and
window update timing remain part of a future hardware latency assessment.

## 5. Window labels and event metrics

For a fall recording with protector contact T1 and hip contact T2:

- Window end before T1-0.5 s: normal (0).
- Window end in [T1-0.5 s, T1): uncertain (-1), not scored or fitted.
- Window end in [T1, T2+2 s]: fall (1).
- Later ends: unscored (-1), because post-fall handling is not fully annotated.

All ends in nonfall records are normal. Every full window is predicted and
exported, including unscored windows. A whole fall file is not labeled positive.

Window metrics: TN, FP, FN, TP, accuracy, precision, recall, F1, F2, balanced
accuracy, average precision and scored/ignored counts. The positive class is
fall. Precision = TP/(TP+FP), recall = TP/(TP+FN),
F1 = 2TP/(2TP+FP+FN), F2 = 5TP/(5TP+4FN+FP).

Alarm emission uses a rising positive decision and a 5-second refractory period
without accessing labels. A contact-associated event match is an emitted alarm
in [T1-0.5, T2+2]. Negative contact delay is explicitly an uncertain guard match,
not verified early instability detection. Alarms before this interval are false;
later post-event alarms are separately unscored. Nonfall-file alarms are false.
Window decisions, positive-window detection and emitted-event matching are
different measurements and remain separately inspectable.

## 6. RF100 fitting and model selection

100 trees; max_depth 8; min_samples_leaf 1; bootstrap True; max_features sqrt;
random_state 42. All candidates use the same 24 features. There is no epoch loop.
At a node, CART finds a feature threshold reducing Gini impurity; forest
randomization uses bootstrap samples and per-node feature subsets. The final
fall score is the mean of the trees' leaf-class probabilities (native sklearn
predict_proba), not a guaranteed calibrated real-world fall probability.

TRAIN sample mass is balanced by class, then original parent, then measured vs
synthetic category, then recording within that category. Scored windows share
their recording/class mass. This prevents 100 descendants from automatically
giving their parent 100 times the influence of measured data.

Fit measured-only and mixed candidates if completed TRAIN augmentation exists.
Tune each threshold over 0.05..0.95 on the two real VALIDATION files. Prefer
event recall, then F2, then fewer false alarm events, then shorter nonnegative
contact delay. Exact threshold ties prefer higher thresholds; exact candidate
ties prefer mixed. Freeze/hash the choice before numeric real TEST reads.

Report fixed-candidate TEST scores without changing the choice. Evaluate held-out
augmentation only afterward. Keep original-test, augmented-stress, fitted TRAIN
and all-data diagnostics in separate tables/matrices. Synthetic descendants
do not increase the independent real-event count. Do not tune using TEST.

## 7. Runtime and reproducibility

Full-file and sample-by-sample inference share the SOS filter, decimation phase,
feature code, threshold and alarm logic. A test checks numerical equivalence
and verifies that changing future samples cannot change prior features.
Independent recordings reset state; the sequential display CSV marks boundaries.

Feature caches bind source hashes, label metadata, frozen calibration,
settings and implementation fingerprints. The frozen choice and stage log make
the order reviewable. Code is modular and commented in English. Windows Python
3.11 dependency compatibility is declared by the pinned packages; validation
was performed on Linux. Native Windows/MATLAB/ESP execution is not claimed.
