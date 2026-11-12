function calibration = load_or_estimate_calibration(projectRoot, runDirectory, config, manifest)
    % LOAD_OR_ESTIMATE_CALIBRATION Reuse a verified prior or estimate it from BUILD.
    % Output: shared calibration K; no TEST values are used for this estimate.

    candidate = fullfile(runDirectory, 'CANDIDATE_CONFIGURATION.mat');
    if isfile(candidate)
        saved = load(candidate, 'K');
        assert(strcmp(hash_file(candidate), strtrim(fileread([candidate '.sha256']))), ...
               'Saved calibration changed.');
        calibration = saved.K;
        return
    end

    calibration = estimate_calibration(projectRoot, config, manifest);
    K = calibration;
    save(candidate, 'K');
    file = fopen([candidate '.sha256'], 'w');
    assert(file >= 0, 'Cannot write the calibration checksum.');
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%s\n', hash_file(candidate));
    write_json(fullfile(runDirectory, 'CANDIDATE_CONFIGURATION.json'), ...
               struct('C', config, 'K', calibration));
end
