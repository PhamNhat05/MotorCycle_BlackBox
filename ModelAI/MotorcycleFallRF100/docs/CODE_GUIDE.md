# Code map: input, transformation, output

| File | Input | Work | Output |
|---|---|---|---|
| train.py | CLI paths/options | Resolve result path and invoke ordered workflow | Result directory |
| predict.py | Frozen bundle + one/many CSVs | Causal batch or sample replay; independent session boundaries | Prediction CSVs, input audit |
| config/parents.json | Supplied source manifest | Fixed AI split and contact annotations | Ten parent identities |
| config/settings.json | Declared experimental settings | Fixed RF100, filter, window, labels, thresholds | Shared settings |
| rf100/io.py | Raw/generated CSV, file bytes | Named column validation, unit contract, timing and SHA-256 | time, six-axis matrix, frequency |
| rf100/calibration.py | Six TRAIN originals | Quiet-prefix gyro estimate; analytic variant rebase | Frozen prior and corrected in-memory variant |
| rf100/dataset.py | Generator manifest and sidecars | Resolve current layout, validate provenance; create verified feature cache | Parent-bound feature records |
| rf100/features.py | Full record or one 200-sample window | Causal SOS, decimation, 24 features | End timestamps and [windows,24] matrix |
| rf100/metrics.py | Scores, contacts, threshold | Endpoint labels, rising-edge alerts, separate class/event scores | Confusion counts and event metrics |
| rf100/training.py | TRAIN records, real VALIDATION | Balanced sample weights, fit RF100, select threshold | Model, fit metadata, selection evidence |
| rf100/pipeline.py | Fixed metadata and selected source directories | Enforce TRAIN→VALIDATION→freeze→TEST→stress order | Bundles, CSV tables, full-window predictions |
| rf100/report.py | Frozen results and raw display signals | White-background HTML, vector charts, class tables | REPORT.html, SVG, PNG |
| rf100/stream.py | One sample/block at a time | Persistent SOS, decimation phase, 200-sample ring, hop 50 | Fall score, decision, alarm |
| tests/test_core.py | Mathematical fixtures and supplied raw data | Integrity, labels, weights, rebase, spectral meaning, causal equivalence | Automated check results |

Execution stages are appended to STAGES.jsonl. The original source metadata and
actual per-recording window counts are written to DATASET_AUDIT.csv. Expensive
feature extraction is cached; processed numeric CSVs are never rewritten.

The streaming API has no serial-device dependency. Your acquisition program can
instantiate StreamingPredictor(bundle, source_hz=1000), then call push(time_s,
six_axis_sample) or push_block(time_array, sample_matrix). Returned None means
the next full-window update is not due. A timestamp gap raises an error rather
than silently treating disconnected measurements as a continuous signal.
