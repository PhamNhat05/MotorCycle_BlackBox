function runDirectory = initialize_original_results(projectRoot, C, manifest, runDirectory)
    % INITIALIZE_ORIGINAL_RESULTS Create result metadata or validate a resumed run.
    % Inputs: root, original configuration, input manifest and optional run path.
    % Output: ORIGINAL/results run; resuming requires identical inputs/code/settings.

    codeManifest = create_code_manifest(projectRoot, 'original');
    if ~isempty(runDirectory)
        saved = load(fullfile(runDirectory, 'RUN_STATE.mat'));
        assert(isequaln(saved.C, C) && isequaln(saved.manifest, manifest), ...
               'Original settings or inputs changed. Start RUN_ORIGINAL again.');
        assert(isequaln(saved.codeManifest, codeManifest), ...
               'Original source code changed. Start a new original run.');
        return
    end

    name = ['RUN_' datestr(now, 'yyyymmdd_HHMMSS_FFF')];
    runDirectory = fullfile(projectRoot, 'ORIGINAL', 'results', name);
    mkdir(runDirectory);
    save(fullfile(runDirectory, 'RUN_STATE.mat'), 'C', 'manifest', 'codeManifest');
    write_json(fullfile(runDirectory, 'DECLARED_SETTINGS.json'), C);
    writetable(codeManifest, fullfile(runDirectory, 'CODE_SHA256.csv'));
    copyfile(fullfile(projectRoot, 'ORIGINAL', 'docs'), fullfile(runDirectory, 'documentation'));
    copyfile(fullfile(projectRoot, 'ORIGINAL', 'config', 'INPUT_MANIFEST.json'), ...
             fullfile(runDirectory, 'INPUT_MANIFEST.json'));
    file = fopen(fullfile(projectRoot, 'ORIGINAL', 'results', 'LATEST_RUN.txt'), 'w');
    assert(file >= 0, 'Cannot update the latest original-run pointer.');
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%s\n', name);
end
