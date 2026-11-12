function variant = compute_sensor_variant(model, sampled, recipe, config)
    % COMPUTE_SENSOR_VARIANT Apply one fixed position shift and constant sensor bias.
    % Inputs: original model, sampled forward IMU, one recipe and augmentation bounds.
    % Output: signals, position component, six bias offsets, shift and consistency error.
    % The latent motion is fixed. Gyro is unchanged by position-only translation.

    biasDelta = [recipe.DeltaAx recipe.DeltaAy recipe.DeltaAz ...
                 recipe.DeltaGx recipe.DeltaGy recipe.DeltaGz];
    positionShift = [recipe.DeltaX_m recipe.DeltaY_m recipe.DeltaZ_m];
    assert(norm(positionShift) <= config.position_delta_max_norm_m + 1e-12);
    assert(all(abs(biasDelta) <= [config.acc_bias_delta_bound_m_s2 ...
                                  config.gyro_bias_delta_bound_deg_s] + 1e-12));

    % Fixed lever-arm acceleration: tangential plus centripetal contribution.
    count = numel(model.time_source_s);
    leverShift = repmat(positionShift, count, 1);
    omega = sampled.omega_body_rad_s;
    alpha = sampled.alpha_body_rad_s2;
    accelerationDelta = (cross(alpha, leverShift, 2) ...
                         + cross(omega, cross(omega, leverShift, 2), 2)) * model.K.sensor_to_body;
    positionComponent = [accelerationDelta zeros(count, 3)];
    signals = sampled.imu + positionComponent + biasDelta;
    assert(all(isfinite(signals), 'all'), 'A variant contains nonfinite values.');

    % Group invariants make the intended source of each change explicit.
    if strcmp(recipe.Group, 'position_only')
        assert(isequal(signals(:, 4:6), sampled.imu(:, 4:6)));
    elseif strcmp(recipe.Group, 'bias_only')
        assert(max(abs((signals - sampled.imu) - biasDelta), [], 'all') < 1e-9);
    end

    % Independently query the complete forward model at selected source timestamps.
    indices = unique(round(linspace(1, count, min(23, count))));
    exact = query_imu(model, model.time_source_s(indices), ...
                      model.K.nominal_position_body_m + positionShift, model.K.bias + biasDelta);
    forwardError = max(abs(exact.imu - signals(indices, :)), [], 'all');
    assert(forwardError < 1e-6, 'Affine augmentation and the forward model disagree.');

    variant = struct('signals', signals, 'position_component', positionComponent, ...
                     'bias_delta', biasDelta, 'position_delta_body_m', positionShift, ...
                     'forward_consistency_max_abs', forwardError);
end
