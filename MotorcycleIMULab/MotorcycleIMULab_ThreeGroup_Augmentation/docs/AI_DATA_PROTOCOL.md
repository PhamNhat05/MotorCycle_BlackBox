# AI data protocol: what 1000 variants establish

## Data count and independence

The ten real recordings contain four fall recordings and six nonfall recordings. The exporter adds 100 variants per parent. It increases sensor-offset diversity around the ten reconstructed motions; it does not create independent riders, roads, speeds, falls or contact dynamics. Row counts and window counts are not independent-event counts. There is no defensible guarantee of AI performance from the number 1000 alone.

This is enough to begin a prototype experiment and compare augmentation methods, conditional on appropriate labels and an independent real-data evaluation. Generalization to real deployment remains unestablished with only four independent recorded falls.

## Group before augmentation/windowing

`ParentKey` is the minimum grouping unit. The measured parent, all its reconstruction-derived variants and all overlapping windows must stay in the same partition. If multiple parents share an identified rider/session, grouping at that higher level is preferable for that generalization target. Rider/session independence is not known from the supplied files.

The original three reconstruction TEST parents remain held out:

- fall_slippery_straight
- acceleration_curve
- fall_like_3

Their 300 synthetic variants are tagged `HoldoutStressOnly=true`. They are never training data. Evaluate the final AI primarily on the three real measured TEST files; synthetic descendants are a separate robustness experiment and must not be reported as 300 independent real tests.

## Provisional five/two/three allocation

| AI role | Parent keys | Real fall/nonfall records | Synthetic descendants |
|---|---|---|---:|
| TRAIN | fall_curve; fall_leaning; acceleration_straight; fall_like_1; fall_like_2 | 2 / 3 | 500 |
| VALIDATION | fall_roundabout; harsh_braking_straight | 1 / 1 | 200, robustness only |
| TEST | fall_slippery_straight; acceleration_curve; fall_like_3 | 1 / 2 | 300, robustness only |

Train on measured TRAIN windows and selected TRAIN-derived variants. Select models/thresholds using real VALIDATION windows/events. Keep real TEST for final evaluation. Report synthetic validation/test stress results separately. Parent counts, not synthetic-file counts, describe the independent sample size of this experiment.

**Generator calibration caveat:** the current reconstruction's common gyro prior was estimated from all seven BUILD recordings. Two of those are proposed here as AI VALIDATION parents. A post-hoc 5:2:3 split therefore does not make the existing generator calibration strictly TRAIN-only. The exporter checks the actual calibration parent keys and exposes `StrictTrainOnlyGeneratorCalibration=false` when appropriate. It does not silently claim a fully independent AI validation experiment.

For a strict AI protocol, first fix the parent split; estimate generator calibration and learned preprocessing using only the five TRAIN parents (or independent external calibration); freeze these; regenerate training variants using that calibration; and fit normalizers/features/AI only on TRAIN. The present add-on reuses the existing frozen models as requested and does not make that recalibration change. A pilot with the current generator must disclose its shared BUILD calibration. The final original three TEST parents are still absent from the shared calibration, as checked from the saved source keys.

## Labels and windows

Full fall recordings contain ordinary motion and post-event handling. Do not assign a positive fall label to every row/window because `record_contains_fall=true`. The supplied T1/T2 annotations indicate crash-protector and hip contact, not a verified pre-fall onset.

Choose the task before windowing: fall detection, impact detection and pre-fall prediction require different targets and timing. Preserve the original event timing in every synthetic descendant. Do not invent sample labels from a filename. Keep ambiguous or unavailable labels explicitly unassigned until the labeling rule is defined.

For a causal deployed detector, avoid using future samples in preprocessing or windows. This reconstruction uses offline conditioning/central differentiation; excellent synthetic results alone do not establish online detector performance. Evaluate the eventual causal AI pipeline on measured held-out streams.

## Compare augmentation with a real baseline

Use the same parent partition, window labels, AI architecture and tuning budget for:

1. Real TRAIN data only.
2. Real TRAIN + bias-only variants.
3. Real TRAIN + position-only variants.
4. Real TRAIN + combined bias/position variants.
5. Real TRAIN + all three groups.

Control synthetic sampling/weights so that a benefit is not merely due to more optimizer steps or one heavily repeated parent. Fit scaling and feature selection on TRAIN only. Compare on the same real validation/test streams; do not choose the winning model after repeatedly inspecting final TEST scores.

Report a confusion matrix, fall precision/recall/F1, false alarms per unit of observed time and detection delay for the chosen event rule, plus PR-AUC when probabilistic window scores and labels support it. Report counts of independent events and missed events. A TEST set containing one true fall gives little evidence about performance across fall types; hundreds of clones do not change that limitation.

No AI model, leakage-free final split, valid online onset labels or improvement claim is produced by this exporter. These require the explicit training/evaluation steps above.
