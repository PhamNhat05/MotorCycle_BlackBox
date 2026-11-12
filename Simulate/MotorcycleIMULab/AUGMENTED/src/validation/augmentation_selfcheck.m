function checks = augmentation_selfcheck()
% AUGMENTATION_SELFCHECK Check counts, bounds and the extracted generation function.
% Inputs: none. Outputs: synthetic-only numerical validation summary.

config = AUGMENTATION_CONFIG();
sample = struct('key', 'synthetic', 'split', 'build', ...
    'record_contains_fall', false, 'samples', 101);
manifest = repmat(sample, 10, 1);
for index = 1:10
    manifest(index).key = sprintf('synthetic_%02d', index);
    if index > 7
        manifest(index).split = 'test';
    end
end
plan = create_augmentation_plan(config, manifest);
assert(numel(plan) == 1000, 'Ten parents must produce 1000 variants.');
groups = {'bias_only', 'position_only', 'bias_and_position'};
expected = [34 33 33];
for index = 1:10
    entries = plan(strcmp({plan.ParentKey}, manifest(index).key));
    assert(numel(entries) == 100);
    for groupIndex = 1:3
        assert(sum(strcmp({entries.Group}, groups{groupIndex})) == expected(groupIndex));
    end
end
for index = 1:numel(plan)
    recipe = plan(index);
    shift = [recipe.DeltaX_m recipe.DeltaY_m recipe.DeltaZ_m];
    bias = [recipe.DeltaAx recipe.DeltaAy recipe.DeltaAz ...
        recipe.DeltaGx recipe.DeltaGy recipe.DeltaGz];
    assert(norm(shift) <= config.position_delta_max_norm_m + 1e-12);
    assert(all(abs(bias) <= [config.acc_bias_delta_bound_m_s2 ...
        config.gyro_bias_delta_bound_deg_s] + 1e-12));
    if strcmp(recipe.Group, 'bias_only')
        assert(all(shift == 0));
    elseif strcmp(recipe.Group, 'position_only')
        assert(all(bias == 0));
    end
end

% An independent second derivative of a rotated point checks the lever formula.
time = 0.73;
step = 1e-4;
lever = [0.31 -0.19 0.11]';
angle = @(t) 0.3 * t + 0.4 * t.^2 + 0.07 * sin(1.7 * t);
rotation = @(t) [cos(angle(t)) -sin(angle(t)) 0; ...
    sin(angle(t)) cos(angle(t)) 0; 0 0 1];
worldAcceleration = (rotation(time + step) * lever ...
    - 2 * rotation(time) * lever + rotation(time - step) * lever) / step^2;
omega = [0 0 0.3 + 0.8 * time + 0.119 * cos(1.7 * time)];
alpha = [0 0 0.8 - 0.2023 * sin(1.7 * time)];
direct = cross(alpha, lever') + cross(omega, cross(omega, lever'));
leverError = max(abs(direct' - rotation(time)' * worldAcceleration));
assert(leverError < 2e-7);

% Exercise the actual generation helper, including a nonidentity sensor mounting.
model = synthetic_model();
sampled = query_imu(model, model.time_source_s);
probes = [1 7 35 40 68 74 100];
largestForwardError = 0;
for index = probes
    variant = compute_sensor_variant(model, sampled, plan(index), config);
    largestForwardError = max(largestForwardError, variant.forward_consistency_max_abs);
    if strcmp(plan(index).Group, 'position_only')
        assert(isequal(variant.signals(:, 4:6), sampled.imu(:, 4:6)));
    elseif strcmp(plan(index).Group, 'bias_only')
        assert(max(abs(std(variant.signals) - std(sampled.imu))) < 1e-12);
    end
end
checks = struct('status', 'PASS', 'counts_per_parent', expected, ...
    'variants_per_parent', 100, 'synthetic_parent_count', 10, 'total_recipes', 1000, ...
    'lever_independent_fd_max_error', leverError, ...
    'generation_helper_forward_max_error', largestForwardError, ...
    'position_delta_max_norm_m', config.position_delta_max_norm_m, ...
    'acc_bias_bounds', config.acc_bias_delta_bound_m_s2, ...
    'gyro_bias_bounds', config.gyro_bias_delta_bound_deg_s, 'synthetic_only', true);
end

function model = synthetic_model()
% Build an analytic rotating sensor with a complete continuous query state.
step = 0.001;
time = (0:step:0.1)';
count = numel(time);
angle = 0.3 * time + 0.4 * time.^2;
omega = [zeros(count, 2) 0.3 + 0.8 * time];
alpha = repmat([0 0 0.8], count, 1);
attitude = [cos(angle / 2) zeros(count, 2) sin(angle / 2)];
attitudeDerivative = 0.5 * quaternion_math('multiply', attitude, [zeros(count, 1) omega]);
model = struct();
model.time_source_s = time;
model.dt_s = step;
model.q = attitude;
model.qd = attitudeDerivative;
model.qdd = 0.5 * quaternion_math('multiply', attitudeDerivative, [zeros(count, 1) omega]) ...
    + 0.5 * quaternion_math('multiply', attitude, [zeros(count, 1) alpha]);
model.K = struct('bias', [0.01 -0.02 0.03 0.1 -0.1 0.2], ...
    'sensor_to_body', quaternion_math('rpy', [3 -4 5]), ...
    'nominal_position_body_m', [0.05 0.01 -0.05], ...
    'gravity_world_m_s2', [0 0 -9.81]);
acceleration = [0.2 * sin(time) 0.3 * cos(time) 0.1 * time];
model.sensor_acceleration_world_m_s2 = acceleration;
model.sensor_velocity_world_m_s = [zeros(1, 3); ...
    cumsum(0.5 * step * (acceleration(1:end - 1, :) + acceleration(2:end, :)), 1)];
model.sensor_position_world_m = [zeros(1, 3); ...
    cumsum(step * model.sensor_velocity_world_m_s(1:end - 1, :) ...
    + step^2 * (acceleration(1:end - 1, :) / 3 + acceleration(2:end, :) / 6), 1)];
end
