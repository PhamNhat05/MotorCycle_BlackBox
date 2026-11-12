function plot_original_comparison(directory, measurements, reconstructed, metrics, config)
    % PLOT_ORIGINAL_COMPARISON Export a high-contrast six-axis original comparison.
    % Outputs: high-resolution PNG and optional vector SVG for sharp HTML zooming.

    visibility = 'off';
    if config.export.figure_visible
        visibility = 'on';
    end
    figureHandle = figure('Visible', visibility, 'Color', 'w', ...
                          'Position', [40 40 1920 1180], 'Renderer', 'painters');
    cleanup = onCleanup(@() close(figureHandle));
    indices = select_display_indices([measurements(:, 2:7) reconstructed], ...
                                     config.export.maximum_plot_bins);

    for axisIndex = 1:6
        axesHandle = subplot(3, 2, axisIndex, 'Parent', figureHandle);
        plot(axesHandle, measurements(indices, 1), measurements(indices, axisIndex + 1), ...
             'Color', [0.04 0.16 0.30], 'LineWidth', 1.25);
        hold(axesHandle, 'on');
        plot(axesHandle, measurements(indices, 1), reconstructed(indices, axisIndex), ...
             'Color', [0.78 0.16 0.04], 'LineWidth', 1.20, 'LineStyle', '--');
        grid(axesHandle, 'on');
        xlim(axesHandle, measurements([1 end], 1)');
        set(axesHandle, 'FontName', 'Arial', 'FontSize', config.export.chart_font_size, ...
            'XColor', [0.05 0.07 0.10], 'YColor', [0.05 0.07 0.10], ...
            'LineWidth', 1, 'GridAlpha', 0.20, 'Color', 'w');
        title(axesHandle, sprintf('%s | RMSE %.4g | r %.4f | fit %.2f%%', ...
                                  char(string(metrics.Axis(axisIndex))), metrics.RMSE(axisIndex), ...
                                  metrics.PearsonR(axisIndex), metrics.NRMSEFit_percent(axisIndex)), ...
              'Interpreter', 'none', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel(axesHandle, 'Source time (s)', 'FontWeight', 'bold');
        ylabel(axesHandle, char(string(metrics.Unit(axisIndex))), 'FontWeight', 'bold');
        legend(axesHandle, 'Original measured', 'Reconstructed', ...
               'Location', 'best', 'FontSize', 12, 'TextColor', [0.05 0.07 0.10]);
    end
    [~, recordKey] = fileparts(directory);
    sgtitle(figureHandle, sprintf('ORIGINAL | %s | %d full-record samples per axis', ...
                                  recordKey, size(measurements, 1)), 'Interpreter', 'none', ...
            'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
    exportgraphics(figureHandle, fullfile(directory, 'FULL_RECORD_FIT.png'), ...
                   'Resolution', config.export.png_dpi, 'BackgroundColor', 'white');
    if config.export.export_svg
        % PRINT supports SVG in MATLAB R2023a; exportgraphics SVG needs newer MATLAB.
        set(figureHandle, 'PaperPositionMode', 'auto');
        print(figureHandle, fullfile(directory, 'FULL_RECORD_FIT.svg'), '-dsvg', '-painters');
    end
end
