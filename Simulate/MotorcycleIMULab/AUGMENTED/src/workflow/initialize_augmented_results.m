function runDirectory = initialize_augmented_results(projectRoot, runDirectory, A, context, recipe_plan)
    % INITIALIZE_AUGMENTED_RESULTS Create run metadata or validate an interrupted run.
    % Resuming requires the same configuration, recipes, source models and code.

    manifest = context.manifest;
    sourceHashes = context.modelHashes;
    frozenHash = context.frozenHash;
    original_run_name = context.originalRunName;
    codeManifest = create_code_manifest(projectRoot, 'augmented');

    if ~isempty(runDirectory)
        saved = load(fullfile(runDirectory, 'AUGMENT_STATE.mat'));
        assert(isequaln(saved.A, A) && isequaln(saved.manifest, manifest) ...
               && isequaln(saved.recipe_plan, recipe_plan), ...
               'Augmentation settings or recipes changed. Start RUN_AUGMENT again.');
        assert(isequaln(saved.codeManifest, codeManifest) ...
               && isequaln(saved.sourceHashes, sourceHashes) ...
               && strcmp(saved.frozenHash, frozenHash), ...
               'Augmentation code or source models changed. Start a new run.');
        return
    end

    name = ['RUN_' datestr(now, 'yyyymmdd_HHMMSS_FFF')];
    runDirectory = fullfile(projectRoot, 'AUGMENTED', 'results', name);
    mkdir(runDirectory);
    save(fullfile(runDirectory, 'AUGMENT_STATE.mat'), 'A', 'manifest', ...
         'recipe_plan', 'sourceHashes', 'frozenHash', 'codeManifest', 'original_run_name');
    write_json(fullfile(runDirectory, 'SETTINGS.json'), A);
    writetable(codeManifest, fullfile(runDirectory, 'CODE_SHA256.csv'));
    write_json(fullfile(runDirectory, 'ORIGINAL_RUN.json'), ...
               struct('original_run_name', original_run_name, 'frozen_sha256', frozenHash, ...
               'original_model_sha256', {sourceHashes}));
    file = fopen(fullfile(projectRoot, 'AUGMENTED', 'results', 'LATEST_RUN.txt'), 'w');
    assert(file >= 0, 'Cannot update the latest augmented-run pointer.');
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%s\n', name);
end
