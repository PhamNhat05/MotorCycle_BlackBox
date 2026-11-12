# Primary references and exact use

References identify the original scientific/technical basis of equations. Project acceptance thresholds, initialization priors, numerical block size, display geometry and augmentation bounds are explicitly project decisions. No earlier project version is treated as a scientific source.

| ID | Primary source | What it supports here |
|---|---|---|
| R1 | A. Boubezoul, F. Dufour, S. Bouaziz, B. Larnaudie, S. Espie, “Dataset on powered two wheelers fall and critical events detection,” Data in Brief 23 (2019), 103828. [DOI](https://doi.org/10.1016/j.dib.2019.103828); [full text and supplements](https://pmc.ncbi.nlm.nih.gov/articles/PMC6660605/) | Published data origin, acquisition description, six channels, 1000 Hz and contact-time annotations. |
| R2 | A. Boubezoul, F. Dufour, S. Bouaziz, S. Espie, “Corrigendum to Dataset on powered two wheelers fall and critical events detection,” Data in Brief 30 (2020), 105577. [DOI](https://doi.org/10.1016/j.dib.2020.105577); [full text and corrected supplement](https://pmc.ncbi.nlm.nih.gov/articles/PMC7303291/) | Ay conversion error and existence of corrected fall recordings. The corrected supplement is mmc1.zip. |
| R3 | J. Sola, “Quaternion kinematics for the error-state Kalman filter” (2017), arXiv:1711.02508. [DOI](https://doi.org/10.48550/arXiv.1711.02508); [author paper](https://arxiv.org/html/1711.02508v1) | Hamilton quaternion conventions, angular-rate integration and inertial specific-force/bias kinematics. See quaternion time derivatives/integration and IMU nominal kinematics sections. This project does not implement the paper's ESKF. |
| R4 | C. de Boor, “On calculating with B-splines,” Journal of Approximation Theory 6 (1972), 50–62. [DOI](https://doi.org/10.1016/0021-9045(72)90080-9) | B-spline basis evaluation foundation. The sparse block arrangement and penalties are project designs. |
| R5 | SciPy, official `BSpline` documentation. [Link](https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.BSpline.html) | Explicit Cox–de Boor recurrence and partition-of-unity definition; independent host comparison. SciPy is not a MATLAB runtime dependency. |
| R6 | NIST Digital Library of Mathematical Functions, Chapter 3: [section 3.3, interpolation](https://dlmf.nist.gov/3.3) and [section 3.4, differentiation](https://dlmf.nist.gov/3.4) | Interpolation/polynomial-differentiation background. The normalized quaternion quintic coefficients and endpoint finite-difference weights are derived in this project from the stated constraints, not quoted as a NIST quaternion algorithm. |
| R7 | MathWorks, “Generate Off-Centered IMU Readings.” [Official example](https://www.mathworks.com/help/nav/ug/generate-off-center-imu-readings.html) | Rigid-body sensor-offset acceleration and rotational/translation sensor effects. The code implements the cross-product formula directly; it does not call `transformMotion` or require Navigation Toolbox. |
| R8 | MathWorks, `compare`: “Compare identified model output with measured output.” [Official documentation](https://www.mathworks.com/help/ident/ref/compare.html) | NRMSE fit-percentage definition. The code calculates the metric directly; it does not require System Identification Toolbox. |

Web sources checked on 2026-11-01. Online software examples may describe newer MATLAB releases; this project uses its own base-MATLAB equations rather than relying on those newer APIs.

## Source boundaries

R1/R2 describe the experiment and data. They do not provide a validated rider contact simulator, the nominal lever-arm numbers in this project, or a guarantee that the supplied CSV bytes are the corrected publisher edition. R3 provides kinematic conventions; a kinematic identity does not solve position observability. R4/R5 support the basis recurrence, not the acceptance thresholds. R7 supports the geometry of a displaced sensor, not the statistical realism of arbitrary perturbation ranges. R8 defines a fit metric, not evidence of downstream model improvement.

See `FORMULA_SOURCE_MAP.csv` for the equation-to-function map and `DATA_PROVENANCE.md` for the exact file lineage and unresolved edition check.
