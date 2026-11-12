function files = get_variant_paths(runDirectory, recipe)
    % GET_VARIANT_PATHS Define all output names for exactly one augmented variant.
    % Output fields include signals, PNG, SVG, HTML, metrics, recipe and completion.

    directory = fullfile(runDirectory, 'records', recipe.ParentKey, recipe.Group);
    stem = fullfile(directory, sprintf('variant_%03d', recipe.VariantIndex));
    files = struct('csv', [stem '.csv'], 'plot', [stem '.png'], ...
                   'vector', [stem '.svg'], 'report', [stem '.html'], ...
                   'metrics', [stem '_STATS.csv'], 'definition', [stem '.json'], ...
                   'completion', [stem '.complete.json']);
end
