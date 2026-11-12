function T = compute_variant_metrics(t, raw, baseline, Y, positionDelta, db)
    % COMPUTE_VARIANT_METRICS Separate total, augmentation, position, bias and baseline changes.
    % Inputs: t/raw/baseline/Y: full records; positionDelta: N-by-6; db: constant 1-by-6 bias.
    % Outputs: T: six-axis table with full-record errors, extrema, timestamps and components.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Full-record metrics; each row describes one axis of one variant.
    total = Y - raw;
    augmentation = Y - baseline;
    residual = baseline - raw;
    axis = {'Ax'; 'Ay'; 'Az'; 'Gx'; 'Gy'; 'Gz'};
    unit = {'m/s^2'; 'm/s^2'; 'm/s^2'; 'deg/s'; 'deg/s'; 'deg/s'};
    rmse = sqrt(mean(total.^2, 1))';
    mae = mean(abs(total), 1)';
    [maxAbs, ix] = max(abs(total), [], 1);
    maxAbs = maxAbs';
    peakTime = t(ix);
    peakTime = peakTime(:);
    meanDelta = mean(total, 1)';
    augRms = sqrt(mean(augmentation.^2, 1))';
    augMax = max(abs(augmentation), [], 1)';
    baseRms = sqrt(mean(residual.^2, 1))';
    positionRms = sqrt(mean(positionDelta.^2, 1))';
    positionMax = max(abs(positionDelta), [], 1)';
    bias = reshape(db, 6, 1);
    originalStd = std(raw, 0, 1)';
    augmentedStd = std(Y, 0, 1)';
    T = table(axis, unit, repmat(numel(t), 6, 1), rmse, mae, maxAbs, peakTime, meanDelta, augRms, augMax, baseRms, positionRms, positionMax, bias, originalStd, augmentedStd, ...
            'VariableNames', {'Axis', 'Unit', 'Samples', 'RMSE_vs_original', 'MAE_vs_original', 'MaxAbs_vs_original', 'TimeMaxAbs_s', ...
                      'MeanDelta_vs_original', 'RMSE_augmentation_only', 'MaxAbs_augmentation_only', 'RMSE_baseline_vs_original', ...
                      'RMSE_position_component', 'MaxAbs_position_component', 'BiasDelta', 'OriginalStd', 'AugmentedStd'});
end
