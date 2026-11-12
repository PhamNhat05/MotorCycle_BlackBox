function zoom = plot_augmented_comparison(pngPath, svgPath, model, sampled, variant, record, recipe, metrics, config)
    % PLOT_AUGMENTED_COMPARISON Draw one variant with readable labels and dark lines.
    % Inputs: output paths, original model, sampled baseline, variant and metadata.
    % Outputs: a PNG, optional SVG, and the exact detail-window description.

    time = model.time_source_s;
    raw = model.measured_imu;
    baseline = sampled.imu;
    signals = variant.signals;
    position = variant.position_component;
    bias = variant.bias_delta;
    shift = variant.position_delta_body_m;
    zoom = choose_detail_window(time, raw, position, record, config);
    detail = time >= zoom.start_s & time <= zoom.end_s;
    totalDifference = signals - raw;
    baselineError = baseline - raw;

    figureHandle = figure('Visible', 'off', 'Color', 'w', ...
                          'Position', [20 20 2250 1920], 'Renderer', 'painters');
    cleanup = onCleanup(@() close(figureHandle));
    layout = tiledlayout(figureHandle, 6, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    layout.OuterPosition = [0 0.05 1 0.81];
    colors = struct('raw', [0.04 0.16 0.30], 'augmented', [0.78 0.16 0.04], ...
                    'position', [0.40 0.16 0.59], 'bias', [0.48 0.30 0.00], ...
                    'baseline', [0.30 0.37 0.45]);

    for axisIndex = 1:6
        % Left: full recording, with extrema-preserving display reduction only.
        axesHandle = nexttile(layout);
        hold(axesHandle, 'on');
        reduced_curve(axesHandle, time, raw(:, axisIndex), config.plot_bins, colors.raw, '-', 1.2);
        reduced_curve(axesHandle, time, signals(:, axisIndex), config.plot_bins, colors.augmented, '--', 1.2);
        xlim(axesHandle, time([1 end])');
        format_axes(axesHandle, config.chart_font_size);
        ylabel(axesHandle, sprintf('%s [%s]', ...
                                   char(string(metrics.Axis(axisIndex))), char(string(metrics.Unit(axisIndex)))), ...
               'Interpreter', 'none', 'FontWeight', 'bold');
        if axisIndex == 1
            title(axesHandle, 'FULL RECORDING', 'FontSize', 16, 'FontWeight', 'bold');
        end
        if axisIndex == 6
            xlabel(axesHandle, 'Source time (s)', 'FontWeight', 'bold');
        end

        % Middle: every original 1 ms sample inside the selected detail interval.
        axesHandle = nexttile(layout);
        hold(axesHandle, 'on');
        plot(axesHandle, time(detail), raw(detail, axisIndex), ...
             'Color', colors.raw, 'LineWidth', 1.45);
        plot(axesHandle, time(detail), signals(detail, axisIndex), ...
             'Color', colors.augmented, 'LineStyle', '--', 'LineWidth', 1.4);
        xlim(axesHandle, [zoom.start_s zoom.end_s]);
        format_axes(axesHandle, config.chart_font_size);
        if axisIndex == 1
            title(axesHandle, 'DETAIL AT ORIGINAL SAMPLE RATE', 'FontSize', 16, 'FontWeight', 'bold');
        end
        if axisIndex == 6
            xlabel(axesHandle, 'Source time (s)', 'FontWeight', 'bold');
        end

        % Right: separate position, bias and baseline-error contributions.
        axesHandle = nexttile(layout);
        hold(axesHandle, 'on');
        reduced_curve(axesHandle, time, totalDifference(:, axisIndex), ...
                      config.plot_bins, colors.augmented, '-', 1.25);
        reduced_curve(axesHandle, time, position(:, axisIndex), ...
                      config.plot_bins, colors.position, '-.', 1.1);
        yline(axesHandle, bias(axisIndex), 'Color', colors.bias, ...
              'LineStyle', '--', 'LineWidth', 1.35);
        reduced_curve(axesHandle, time, baselineError(:, axisIndex), ...
                      config.plot_bins, colors.baseline, ':', 1.1);
        xlim(axesHandle, time([1 end])');
        format_axes(axesHandle, config.chart_font_size);
        if axisIndex == 1
            title(axesHandle, 'DIFFERENCE COMPONENTS', 'FontSize', 16, 'FontWeight', 'bold');
        end
        xlabel(axesHandle, sprintf('RMSE %.4g | max abs. difference %.4g %s', ...
                                   metrics.RMSE_vs_original(axisIndex), metrics.MaxAbs_vs_original(axisIndex), ...
                                   char(string(metrics.Unit(axisIndex)))), 'Interpreter', 'none', ...
               'FontSize', 11, 'FontWeight', 'bold');
    end

    newPosition = model.K.nominal_position_body_m + shift;
    heading = sprintf('%s | variant %03d / 100 | %s', ...
                      record.key, recipe.VariantIndex, strrep(recipe.Group, '_', ' '));
    parameters = sprintf(['Position shift XYZ [m]: [%+.4f %+.4f %+.4f]; length: %.4f m; new position: [%+.4f %+.4f %+.4f] m\n' ...
                          'Acceleration bias [m/s^2]: [%+.4f %+.4f %+.4f]; gyroscope bias [deg/s]: [%+.4f %+.4f %+.4f]'], ...
                         shift, norm(shift), newPosition, bias(1:3), bias(4:6));
    annotation(figureHandle, 'textbox', [0.035 0.958 0.94 0.03], 'String', heading, ...
               'FontName', 'Arial', 'FontSize', 21, 'FontWeight', 'bold', ...
               'Color', [0.04 0.06 0.10], 'EdgeColor', 'none', 'Interpreter', 'none');
    annotation(figureHandle, 'textbox', [0.035 0.908 0.94 0.05], 'String', parameters, ...
               'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', ...
               'Color', [0.04 0.06 0.10], 'EdgeColor', 'none', 'Interpreter', 'none');
    legendText = ['Signals: measured = navy solid; augmented = red dashed. ' ...
                  'Differences: total = red; position = purple; bias = brown dashed; baseline error = slate dotted.'];
    annotation(figureHandle, 'textbox', [0.035 0.872 0.94 0.033], 'String', legendText, ...
               'FontName', 'Arial', 'FontSize', 12, 'Color', [0.04 0.06 0.10], ...
               'EdgeColor', 'none', 'Interpreter', 'none');
    footer = sprintf(['%d full-record samples at 1000 Hz. Detail: %.3f to %.3f s (%s). ' ...
                      'All horizontal axes use source time in seconds. CSV and metrics use every sample.'], ...
                     numel(time), zoom.start_s, zoom.end_s, zoom.reason);
    annotation(figureHandle, 'textbox', [0.035 0.006 0.94 0.035], 'String', footer, ...
               'FontName', 'Arial', 'FontSize', 12, 'Color', [0.04 0.06 0.10], ...
               'EdgeColor', 'none', 'Interpreter', 'none');
    exportgraphics(figureHandle, pngPath, 'Resolution', config.png_dpi, 'BackgroundColor', 'white');
    if config.export_svg
        set(figureHandle, 'PaperPositionMode', 'auto');
        print(figureHandle, svgPath, '-dsvg', '-painters');
    end
end

function zoom = choose_detail_window(time, raw, position, record, config)
    % Prefer the known contact interval; otherwise show the largest relevant change.
    if ~isempty(record.reference_contact_start_s)
        center = mean([record.reference_contact_start_s record.reference_contact_end_s]);
        reason = 'reference contact';
    elseif max(std(position, 0, 1)) > 1e-8
        [~, peak] = max(vecnorm(position(:, 1:3), 2, 2));
        center = time(peak);
        reason = 'largest position effect';
    else
        scale = max(std(raw, 0, 1), [0.1 0.1 0.1 0.5 0.5 0.5]);
        [~, peak] = max(vecnorm((raw - mean(raw, 1)) ./ scale, 2, 2));
        center = time(peak);
        reason = 'strong original-signal variation';
    end
    zoom = struct('start_s', max(time(1), center - config.zoom_half_width_s), ...
                  'end_s', min(time(end), center + config.zoom_half_width_s), 'reason', reason);
end

function reduced_curve(axesHandle, time, signal, bins, color, lineStyle, width)
    % Retain the actual timestamp of each minimum and maximum in every display bin.
    indices = envelope_indices(signal, bins);
    plot(axesHandle, time(indices), signal(indices), 'Color', color, ...
         'LineStyle', lineStyle, 'LineWidth', width);
end

function format_axes(axesHandle, fontSize)
    % Use dark tick labels and slightly stronger axes on a pure white background.
    grid(axesHandle, 'on');
    set(axesHandle, 'FontName', 'Arial', 'FontSize', fontSize, ...
        'XColor', [0.04 0.06 0.10], 'YColor', [0.04 0.06 0.10], ...
        'LineWidth', 1, 'GridAlpha', 0.20, 'Color', 'w');
end

function indices = envelope_indices(signal, bins)
    % Display-only reduction; the full signal is preserved in CSV and all metrics.
    count = numel(signal);
    if count <= 2 * bins
        indices = (1:count)';
        return
    end
    block = ceil(count / bins);
    columns = ceil(count / block);
    padded = [signal(:); nan(block * columns - count, 1)];
    values = reshape(padded, block, columns);
    [~, low] = min(values, [], 1, 'omitnan');
    [~, high] = max(values, [], 1, 'omitnan');
    offset = (0:columns - 1) * block;
    indices = unique([1 count offset + low offset + high])';
    indices = indices(indices <= count);
end
