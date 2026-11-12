function context = validate_original_results(originalRun)
    % VALIDATE_ORIGINAL_RESULTS Verify the read-only inputs for augmentation.
    % Input: a completed ORIGINAL run. Output: frozen settings and model hashes.

    assert(isfile(fullfile(originalRun, 'RUN_STATE.mat')), ...
           'Select an original run containing RUN_STATE.mat.');
    state = load(fullfile(originalRun, 'RUN_STATE.mat'), 'manifest');
    manifest = state.manifest;
    assert(numel(manifest) == 10 && sum(strcmp({manifest.split}, 'build')) == 7 ...
           && sum(strcmp({manifest.split}, 'test')) == 3, 'Expected the original 7:3 split.');
    records = collect_record_status(originalRun, manifest, 'all');
    assert(all([records.completed]) && all([records.pass]), ...
           'All ten original records must be complete and pass their gates.');

    lock = fullfile(originalRun, 'FROZEN_CONFIGURATION.json');
    assert(isfile(lock), 'The original configuration has not been frozen.');
    frozenHash = hash_file(lock);
    assert(strcmp(frozenHash, strtrim(fileread([lock '.sha256']))), ...
           'The frozen original configuration changed.');
    frozen = jsondecode(fileread(lock));
    assert(~frozen.test_values_used_for_common_configuration && ~frozen.K.test_values_used, ...
           'TEST values must not be used to estimate the common calibration.');

    modelHashes = cell(numel(manifest), 1);
    for index = 1:numel(manifest)
        directory = fullfile(originalRun, 'records', manifest(index).key);
        modelFile = fullfile(directory, 'MODEL.mat');
        assert(isfile(modelFile), 'Original model is missing: %s', manifest(index).key);
        quality = jsondecode(fileread(fullfile(directory, 'QUALITY.json')));
        assert(quality.pass && quality.full_record && quality.excluded_samples == 0 ...
               && quality.scored_samples == manifest(index).samples, ...
               'Original full-record gate failed: %s', manifest(index).key);
        modelHashes{index} = hash_file(modelFile);
        assert(strcmp(modelHashes{index}, quality.model_sha256), ...
               'Original model changed: %s', manifest(index).key);
    end
    [~, originalName] = fileparts(originalRun);
    context = struct('manifest', manifest, 'frozen', frozen, ...
                     'frozenHash', frozenHash, 'modelHashes', {modelHashes}, ...
                     'originalRunName', originalName);
end
