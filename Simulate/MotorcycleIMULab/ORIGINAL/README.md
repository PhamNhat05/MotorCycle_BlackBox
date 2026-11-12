# ORIGINAL

Measured inputs are stored under `data/build` and `data/test`.
Call `RUN_ORIGINAL` from the project root. Outputs are written to
`results/RUN_.../`; open `REPORT.html` in that session.

The stage estimates a shared calibration from the seven BUILD recordings,
freezes it, then processes the three TEST recordings without retuning.
It exports full signals, states, numerical fits and sharp SVG/PNG charts.
Movie export is not part of the project.

Source modules are grouped by calibration, conditioning, reconstruction,
evaluation, IO, plotting, reporting, validation and workflow orchestration.
Shared numerical/reporting helpers are reused by AUGMENTED.
