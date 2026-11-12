function M = reconstruct_motion(A, C, K, item)
    % RECONSTRUCT_MOTION Reconstruct one continuous conditional motion model from all IMU samples.
    % Inputs: A: measured N-by-7 record; C: settings; K: calibration; item: source metadata.
    % Outputs: M: full-record states and forward-model diagnostics; no independent trajectory claim.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Conditional mechanization from the complete measured record [R3,R7].
    % 1. Subtract the shared bias and condition every source sample.
    t = A(:, 1);
    h = round(median(diff(t)) * 1e9) / 1e9;
    N = numel(t);
    [Y, coverage] = condition_signals(t, A(:, 2:7) - K.bias, C.conditioning);
    % 2. Convert corrected gyro to body-frame rad/s and differentiate it.
    w = (Y(:, 4:6) * pi / 180) * K.sensor_to_body';
    alpha = differentiate_signal(w, h);
    % 3. Initialize tilt from the declared gravity-dominated prefix.
    use = t >= C.initial.tilt_prefix_s(1) & t <= C.initial.tilt_prefix_s(2) & vecnorm(A(:, 2:4), 2, 2) > 1;
    assert(sum(use) >= 10, 'No usable initialization prefix.');
    f = mean(Y(use, 1:3), 1) * K.sensor_to_body';
    qref = quaternion_math('tilt', f, C.initial.yaw_deg);
    iref = find(use);
    iref = iref(round((numel(iref) + 1) / 2));
    q0 = qref;
    % Move the prefix attitude backward to the first source timestamp.
    for k = iref - 1:-1:1
        dq = quaternion_math('exp', -0.25 * h * (w(k, :) + w(k + 1, :)));
        q0 = quaternion_math('multiply', q0, dq);
        q0 = q0 / norm(q0);
    end
    % 4. Integrate one continuous quaternion chain without block resets.
    q = zeros(N, 4);
    q(1, :) = q0;
    for k = 1:N - 1
        dq = quaternion_math('exp', 0.25 * h * (w(k, :) + w(k + 1, :)));
        q(k + 1, :) = quaternion_math('multiply', q(k, :), dq);
        q(k + 1, :) = q(k + 1, :) / norm(q(k + 1, :));
        if mod(k, 20000) == 0
            fprintf('  Continuous integration: %d / %d samples\n', k, N);
        end
    end
    % Derivatives make the continuous attitude interpolation reproduce node rates.
    qd = 0.5 * quaternion_math('multiply', q, [zeros(N, 1) w]);
    qdd = 0.5 * quaternion_math('multiply', qd, [zeros(N, 1) w]) + 0.5 * quaternion_math('multiply', q, [zeros(N, 1) alpha]);
    % 5. Rotate specific force into world acceleration and restore gravity.
    aS = quaternion_math('rotate', q, Y(:, 1:3) * K.sensor_to_body') + K.gravity_world_m_s2;
    r = repmat(K.nominal_position_body_m, N, 1);
    v0 = C.initial.body_velocity_world_m_s + quaternion_math('rotate', q(1, :), cross(w(1, :), r(1, :), 2));
    p0 = C.initial.body_position_world_m + quaternion_math('rotate', q(1, :), r(1, :));
    % Integrate the piecewise-linear acceleration exactly over each interval.
    vS = [v0; v0 + cumsum(0.5 * h * (aS(1:end - 1, :) + aS(2:end, :)), 1)];
    pS = [p0; p0 + cumsum(h * vS(1:end - 1, :) + h^2 * (aS(1:end - 1, :) / 3 + aS(2:end, :) / 6), 1)];
    % 6. Store the full model and retain the untouched measured signals.
    M.schema = 1;
    M.key = item.key;
    M.item = item;
    M.time_source_s = t;
    M.dt_s = h;
    M.q = q;
    M.qd = qd;
    M.qdd = qdd;
    M.sensor_position_world_m = pS;
    M.sensor_velocity_world_m_s = vS;
    M.sensor_acceleration_world_m_s2 = aS;
    M.K = K;
    M.coverage = coverage;
    M.initialization_reference_source_s = t(iref);
    M.description = 'Full-record conditional kinematic model. IMU fit is an in-sample roundtrip, not independent 3D validation.';
    % 7. Check the nominal forward roundtrip against the conditioned IMU.
    Q = query_imu(M, t, K.nominal_position_body_m, K.bias);
    M.forward_roundtrip_max_abs = max(abs(Q.imu - (Y + K.bias)), [], 'all');
    M.quaternion_norm_max_error = max(abs(vecnorm(q, 2, 2) - 1));
    M.end_body_displacement_m = norm(Q.body_position_world_m(end, :) - Q.body_position_world_m(1, :));
    M.maximum_body_speed_m_s = max(vecnorm(Q.body_velocity_world_m_s, 2, 2));
    M.conditioned_imu = Y + K.bias;
    M.measured_imu = A(:, 2:7);
end
