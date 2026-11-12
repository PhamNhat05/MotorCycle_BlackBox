function manifest = load_original_manifest(projectRoot)
    % LOAD_ORIGINAL_MANIFEST Load and verify the declared ten-parent 7:3 split.
    % Output: record metadata; source timestamps and contact annotations are retained.

    path = fullfile(projectRoot, 'ORIGINAL', 'config', 'INPUT_MANIFEST.json');
    manifest = jsondecode(fileread(path));
    assert(numel(manifest) == 10, 'Expected exactly ten original recordings.');
    assert(sum(strcmp({manifest.split}, 'build')) == 7, 'Expected seven BUILD files.');
    assert(sum(strcmp({manifest.split}, 'test')) == 3, 'Expected three TEST files.');
    assert(numel(unique({manifest.key})) == 10, 'Original record keys must be unique.');
end
