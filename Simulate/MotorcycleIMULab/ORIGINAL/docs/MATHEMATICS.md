# Mathematical model and implementation

## Conventions

W is an inertial frame with gravity g_W = [0, 0, -9.81] m/s^2. B is the modeled motorcycle body frame, chosen with x forward, y left and z up for illustration. S is the sensor frame. R_WB maps B vectors into W. The fixed mounting matrix R_BS maps S vectors into B. Row-vector code uses the transposes implied by this column-vector notation. An unverified installation rotation is a modeling assumption, not a measured calibration.

Quaternions follow the Hamilton scalar-first convention q = [q_w,q_x,q_y,q_z], with active B-to-W rotation. Gyro data are read in deg/s and converted to rad/s internally. Acceleration is treated as specific force in m/s^2. These conventions must be checked against any replacement dataset's sensor triad; the code does not infer axis signs from a visual fit.

## Measurement and lever arm [R3, R7]

For a fixed sensor position r_B relative to the body origin:

$$p_{S,W}=p_{B,W}+R_{WB}r_B,$$

$$a_{S,W}=a_{B,W}+R_{WB}\{\alpha_B\times r_B+\omega_B\times(\omega_B\times r_B)\}.$$

The forward sensor model is

$$f_S=R_{BS}^{T}\{R_{WB}^{T}(a_{B,W}-g_W)+\alpha_B\times r_B+\omega_B\times(\omega_B\times r_B)\}+b_a,$$

$$\omega_{S,\mathrm{deg/s}}={180\over\pi}R_{BS}^{T}\omega_B+b_g.$$

The double-cross term is centripetal acceleration; the angular-acceleration term is tangential acceleration. `query_imu` evaluates these expressions. A constant mounting offset is assumed, so relative-motion/Coriolis terms for a moving sensor are absent.

## Conditioning: project numerical design [R4, R5]

For each overlapping block, represent a corrected channel with degree-five B-splines, z = Bc. Solve

$$\min_c\|Bc-(y-b)\|_2^2+\lambda\|D_dc\|_2^2.$$

D_d is a first coefficient difference for acceleration and a second coefficient difference for gyro. The fixed penalties are 1e-5 and 1e-8 respectively; these are coefficient penalties, not time-normalized physical priors. The knot spacing is 2 ms. Sparse rectangular MATLAB backslash solves the stacked least-squares system; no nonlinear optimizer or toolbox spline fitter is used.

`build_spline_basis` implements local Cox–de Boor recursion. In each overlap, nonnegative cosine ramps blend the block predictions and divide by the total weight. First/last samples have positive support. This engineering arrangement controls solve size while retaining the complete time support. It can smooth high-frequency content; full-record measured-versus-forward errors expose that loss. It is not guaranteed to preserve every impact peak exactly.

Angular acceleration uses a five-point polynomial derivative of the conditioned body angular velocity. Interior weights are [1,-8,0,8,-1]/(12h); one-sided endpoint weights solve the corresponding degree-four moment equations. Differentiation can amplify residual high-frequency noise. Translation augmentation therefore remains conditional on this estimated derivative.

## One continuous state chain [R3]

Corrected body angular velocity is omega_B = R_BS (gyro_S - b_g) pi/180. Tilt is initialized from a fixed 0.5–2 s prefix assumed approximately gravity dominated; yaw is a fixed prior. A reference-prefix orientation is integrated backward to the first sample, then the complete record is integrated forward using midpoint angular velocity and a quaternion exponential:

$$q_{k+1}=q_k\otimes\exp_q\left([0,\bar\omega_{B,k}]h/2\right).$$

No accelerometer feedback continuously corrects tilt; the system does not silently force acceleration to be gravity. Gyro bias or axis errors can consequently produce attitude drift. Initial body velocity is zero by assumption, although the motorcycle may already be moving. Position is therefore not identifiable as a true world trajectory from these channels alone.

At measurement nodes,

$$\dot q=\tfrac12q\otimes[0,\omega_B],\qquad
\ddot q=\tfrac12\dot q\otimes[0,\omega_B]+\tfrac12q\otimes[0,\alpha_B].$$

Obtain nominal sensor acceleration from conditioned specific force:

$$a_{S,W}=R_{WB}R_{BS}(f_S-b_a)+g_W.$$

Between adjacent nodes, assume sensor-world acceleration varies linearly. Exact integration of that interpolation gives

$$v_{S,k+1}=v_{S,k}+\tfrac h2(a_{S,k}+a_{S,k+1}),$$

$$p_{S,k+1}=p_{S,k}+hv_{S,k}+h^2(a_{S,k}/3+a_{S,k+1}/6).$$

Initial sensor position/velocity account for the nominal lever arm. Body states are recovered through p_B = p_S - Rr_0 and v_B = v_S - R(omega cross r_0). This definition makes the nominal accelerometer reconstruction a conditional kinematic roundtrip. It is intentionally not an independent dynamics validation.

## Continuous queries: project derivation [R6]

For normalized interval coordinate s = (t-t_k)/h, let a quintic vector polynomial P(s) match q, h qdot and h^2 qddot at both endpoints. With c0 = q0, c1 = h qdot0, c2 = h^2 qddot0/2, define A = q1-c0-c1-c2, B = h qdot1-c1-2c2, D = h^2 qddot1-2c2. Solving the six endpoint constraints yields

$$c_3=10A-4B+D/2,\quad c_4=-15A+7B-D,\quad c_5=6A-3B+D/2.$$

Normalize P with its analytically differentiated normalization to obtain unit q(t), qdot(t) and qddot(t). Derive angular velocity and acceleration from twice the vector part of conjugate(q) multiplied by qdot and qddot respectively. These endpoint constraints give a C2 attitude representation. The sensor-position cubic obtained by integrating linear acceleration is C2 at nodes because stored position/velocity are carried forward continuously.

The same `query_imu` supplies forward IMU, CSV states, shifted-sensor output and state exports. There is no independent animation path, residual pasted into the forward output, per-block state reset, post-fit road projection or manually aligned endpoint. At original sample times, the output reproduces the conditioned signal to numerical precision; comparison is always against the untouched measured signal.

## Sensor augmentation [R7 plus project choices]

Freeze the nominal motion. Sample one fixed delta r_B and one constant six-axis delta b for a whole parent record. For a translated sensor,

$$\Delta f_S=R_{BS}^{T}\{\alpha_B\times\Delta r_B+\omega_B\times(\omega_B\times\Delta r_B)\}+\Delta b_a,$$

$$\Delta\omega_{S,\mathrm{deg/s}}=\Delta b_g.$$

This affine identity allows CSV streaming without reintegrating the motion. It is checked against `query_imu` at independent sample positions in each export chunk. Each sample must be finite. No unknown hardware full-scale limit is invented and no clipping is applied. The bounds, random seed and number of variants are project choices, not claims from a cited paper. Bias is an additive sensor offset; it is not an objective-function weight.

## Metrics [R8]

For each complete measured channel y and its forward output yhat, report RMSE, MAE, maximum absolute error, sample standard deviation, Pearson r and

$$\mathrm{NRMSE\ fit\ (percent)}=100\left(1-\frac{\|y-\hat y\|_2}{\|y-\mathrm{mean}(y)\|_2}\right).$$

The fit percentage can be negative and is undefined for a constant measured channel. It is not percentage classification accuracy or percentage-correct 3D motion. The acceptance rules are declared in `ORIGINAL_CONFIG`, not sourced as universal scientific thresholds. External position/orientation measurements and a separate downstream task would be needed for stronger validation.
