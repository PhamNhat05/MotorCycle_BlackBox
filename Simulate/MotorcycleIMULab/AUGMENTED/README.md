# AUGMENTED

Input: a completed ORIGINAL session with all ten quality gates passed.
Call `RUN_AUGMENT(originalResults)` from the project root, or omit the argument
to select the latest original results. Outputs are written to `results/RUN_.../`.

Open the session's `INDEX.html`, select a parent, then open an individual variant
report. Every parent has 34 bias-only, 33 position-only and 33 combined variants.

Every variant receives a full CSV, vector SVG, high-resolution PNG, readable HTML
page, six-axis metric table, exact-parameter JSON and verified completion marker.
`AUGMENTATION_CONFIG.m` defines counts, bounds, seed and display quality.

Generation, metrics, plotting, report writing and completion verification are
separate functions in separate source-module directories.
The original model and its latent motion are read without modification.

The report decomposes changes as:

```text
augmented - measured = position_effect + bias_effect + (baseline - measured)
```

Position-only variants leave gyro unchanged relative to the reconstructed
baseline. Any remaining gyro difference from measured data is baseline error.
