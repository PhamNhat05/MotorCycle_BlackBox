function plan = create_augmentation_plan(A, manifest)
    % CREATE_AUGMENTATION_PLAN Declare exactly 100 reproducible sensor variants per real recording.
    % Inputs: A: AUGMENTATION_CONFIG; manifest: original-parent records.
    % Outputs: plan: 34 bias-only, 33 position-only and 33 combined recipes per parent.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Explicit single-axis probes followed by seeded multi-axis scenarios.
    % Count rules are a dataset contract: the three groups must sum to 100.
    counts = [A.counts.bias_only A.counts.position_only A.counts.bias_and_position];
    assert(all(counts >= 1 & counts == floor(counts)) && sum(counts) == 100, 'Each parent must have exactly 100 variants.');
    ba = reshape(A.acc_bias_delta_bound_m_s2, 1, 3);
    bg = reshape(A.gyro_bias_delta_bound_deg_s, 1, 3);
    radius = A.position_delta_max_norm_m;
    assert(all(isfinite([ba bg radius])) && all([ba bg radius] > 0));
    % Signed single-axis probes make individual parameter effects easy to inspect.
    axes = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
    groups = {'bias_only', 'position_only', 'bias_and_position'};
    entries = cell(numel(manifest) * 100, 1);
    row = 0;
    for p = 1:numel(manifest)
        % Each parent receives a local random stream; global MATLAB RNG state is unchanged.
        stream = RandStream('mt19937ar', 'Seed', A.seed + 1000 * (p - 1));
        number = 0;
        item = manifest(p);
        for g = 1:3
            for j = 1:counts(g)
                db = zeros(1, 6);
                dr = zeros(1, 3);
                if g == 1
                    if j <= 6
                        db(1:3) = axes(j, :) .* ba;
                    elseif j <= 12
                        db(4:6) = axes(j - 6, :) .* bg;
                    else
                        db = (2 * rand(stream, 1, 6) - 1) .* [ba bg];
                    end
                elseif g == 2
                    if j <= 6
                        dr = radius * axes(j, :);
                    elseif j <= 12
                        dr = 0.5 * radius * axes(j - 6, :);
                    else
                        dr = random_position(stream, radius);
                    end
                else
                    if j <= 12
                        axis = axes(mod(j - 1, 6) + 1, :);
                        dr = radius * axis;
                        sgn = 1;
                        if j > 6
                            sgn = -1;
                        end
                        db = [sgn * axis .* ba sgn * axis .* bg];
                    else
                        dr = random_position(stream, radius);
                        db = (2 * rand(stream, 1, 6) - 1) .* [ba bg];
                    end
                end
                number = number + 1;
                row = row + 1;
                entries{row} = struct('ParentKey', item.key, 'ParentSplit', item.split, 'RecordContainsFall', item.record_contains_fall, ...
                                    'HoldoutStressOnly', strcmp(item.split, 'test'), 'VariantIndex', number, 'Group', groups{g}, 'GroupIndex', j, 'Samples', item.samples, ...
                                    'DeltaAx', db(1), 'DeltaAy', db(2), 'DeltaAz', db(3), 'DeltaGx', db(4), 'DeltaGy', db(5), 'DeltaGz', db(6), ...
                                    'DeltaX_m', dr(1), 'DeltaY_m', dr(2), 'DeltaZ_m', dr(3), 'PositionDeltaNorm_m', norm(dr), 'Materialized', false);
            end
        end
    end
    plan = [entries{:}];
end

function dr = random_position(stream, radius)
    direction = randn(stream, 1, 3);
    direction = direction / norm(direction);
    dr = direction * radius * rand(stream)^(1 / 3);
end
