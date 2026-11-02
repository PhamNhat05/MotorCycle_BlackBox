# Sensor method and sources

With fixed sensor-to-body mounting R_BS and fixed body-frame translation delta r, hold the reconstructed body motion unchanged. The change in measured acceleration is

$$\Delta f_S=R_{BS}^T\{\alpha_B\times\Delta r+\omega_B\times(\omega_B\times\Delta r)\}+\Delta b_a.$$

The gyro change is only delta b_g for rigid-body translation with unchanged mounting. Bias is an additive sensor offset, not a fitting weight. Each perturbation is constant across a full recording. Group isolation is exact: bias-only uses delta r=0, position-only uses delta b=0, and the combined group uses both.

The MATLAB code evaluates these expressions in row-vector form. It compares sampled results with the saved continuous quaternion/position forward model. Position-only exports verify unchanged gyro. Maxima, maximum changes and finite-output checks are exported; no unknown sensor full-scale limit or saturation behavior is invented. A finite, algebraically consistent variant is not automatically physically representative of real installations.

## Primary references

- MathWorks, [Generate Off-Centered IMU Readings](https://www.mathworks.com/help/nav/ug/generate-off-center-imu-readings.html): rigid-body off-center IMU motion and acceleration. The exporter uses direct cross products, not the Navigation Toolbox API.
- J. Sola (2017), [Quaternion kinematics for the error-state Kalman filter](https://doi.org/10.48550/arXiv.1711.02508): quaternion conventions and IMU kinematics used by the existing continuous model. The bundled `mil_math` and `mil_query` helpers are exact project helper copies; no filter implementation is claimed.
- scikit-learn, [StratifiedGroupKFold](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.StratifiedGroupKFold.html): group-disjoint partitioning.
- scikit-learn, [Common pitfalls: data leakage](https://scikit-learn.org/stable/common_pitfalls.html): split before fitting preprocessing; learn transforms from TRAIN only.
- B. K. Iwana and S. Uchida (2021), [An empirical survey of data augmentation for time series classification with neural networks](https://doi.org/10.1371/journal.pone.0254841), PLOS ONE 16(7), e0254841: augmentation effectiveness depends on the method, data and model. It does not validate this project's particular bias/translation bounds.
- A. Boubezoul et al. (2019), [Dataset on powered two wheelers fall and critical events detection](https://doi.org/10.1016/j.dib.2019.103828), and [2020 corrigendum](https://doi.org/10.1016/j.dib.2020.105577): experimental data origin and Ay edition issue inherited from the parent project.

Bounds ±0.1 m/s^2, ±0.2 deg/s, ±0.02 m and the 34/33/33 allocation are project experimental choices. They are not derived as optimal or universally safe hardware limits from these references. Web references checked 2026-11-01.
