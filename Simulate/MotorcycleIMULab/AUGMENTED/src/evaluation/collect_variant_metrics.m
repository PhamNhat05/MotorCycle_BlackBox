function collect_variant_metrics(runDirectory, plan)
    % COLLECT_VARIANT_METRICS Combine 1,000 six-axis tables into 6,000 metric rows.
    % Input: a fully completed recipe plan. Output: ALL_AXIS_METRICS.csv.

    rows = cell(numel(plan), 1);
    for index = 1:numel(plan)
        files = get_variant_paths(runDirectory, plan(index));
        metrics = readtable(files.metrics, 'TextType', 'string');
        rows{index} = addvars(metrics, ...
                              repmat(string(plan(index).ParentKey), height(metrics), 1), ...
                              repmat(string(plan(index).Group), height(metrics), 1), ...
                              repmat(plan(index).VariantIndex, height(metrics), 1), ...
                              'Before', 1, 'NewVariableNames', {'Parent', 'Group', 'VariantIndex'});
    end
    metrics = vertcat(rows{:});
    assert(height(metrics) == 6000, 'Expected 1000 variants times six axes.');
    writetable(metrics, fullfile(runDirectory, 'ALL_AXIS_METRICS.csv'));
end
