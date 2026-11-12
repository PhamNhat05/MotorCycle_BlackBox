function process_original_record(projectRoot, runDirectory, record, config, calibration)
    % PROCESS_ORIGINAL_RECORD Reconstruct, evaluate and export one full real record.
    % A QUALITY.json marker is committed only after the complete export succeeds.

    directory = fullfile(runDirectory, 'records', record.key);
    marker = fullfile(directory, 'QUALITY.json');
    if isfile(marker)
        quality = jsondecode(fileread(marker));
        modelFile = fullfile(directory, 'MODEL.mat');
        assert(isfile(modelFile) && strcmp(hash_file(modelFile), quality.model_sha256), ...
               'Completed original model changed: %s', record.key);
        fprintf('Reuse completed original record: %s\n', record.key);
        return
    end

    fprintf('%s | %s | %d full-record samples\n', ...
            upper(record.split), record.key, record.samples);
    started = tic;
    measurements = read_original_record(projectRoot, record);
    model = reconstruct_motion(measurements, config, calibration, record);
    [metrics, quality] = evaluate_reconstruction(measurements, model, config);
    quality.reconstruction_elapsed_s = toc(started);
    export_original_record(directory, measurements, model, config, metrics, quality);
end
