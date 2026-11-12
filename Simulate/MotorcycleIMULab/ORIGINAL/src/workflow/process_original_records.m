function runDirectory = process_original_records(projectRoot, config, runDirectory)
    % PROCESS_ORIGINAL_RECORDS Orchestrate full-record reconstruction with a fixed 7:3 split.
    % Inputs: project root, ORIGINAL_CONFIG and optional existing result directory.
    % Output: original run directory. This function never launches augmentation.

    % 1. Validate the experiment identity before reading any measurements.
    manifest = load_original_manifest(projectRoot);
    runDirectory = initialize_original_results(projectRoot, config, manifest, runDirectory);
    for index = 1:numel(manifest)
        assert(strcmp(hash_file(fullfile(projectRoot, manifest(index).relative_path)), ...
                      manifest(index).sha256), 'Original input changed: %s', manifest(index).key);
    end
    fprintf('\nORIGINAL | 7 BUILD followed by 3 TEST | %s\n', runDirectory);
    diary(fullfile(runDirectory, 'RUN_LOG.txt'));
    cleanup = onCleanup(@() diary('off'));

    try
        % 2. Check the numerical kernels, then load a BUILD-only calibration.
        write_json(fullfile(runDirectory, 'MATLAB_SELF_CHECKS.json'), original_selfcheck());
        calibration = load_or_estimate_calibration( ...
                                                   projectRoot, runDirectory, config, manifest);

        % 3. Process BUILD first; freeze the common configuration before TEST.
        for phase = {'build', 'test'}
            split = phase{1};
            if strcmp(split, 'test')
                buildRecords = collect_record_status(runDirectory, manifest, 'build');
                if ~all([buildRecords.completed]) || ~all([buildRecords.pass])
                    write_original_status(runDirectory, ...
                                          'BUILD_GATE_FAILED_TEST_NOT_OPENED', 'Inspect BUILD axis fits.');
                    write_original_report(runDirectory);
                    package_original_results(runDirectory);
                    return
                end
                freeze_original_configuration(runDirectory, config, calibration, manifest);
            end

            recordIndices = find(strcmp({manifest.split}, split));
            for index = recordIndices
                if isfile(fullfile(runDirectory, 'STOP_AFTER_CURRENT_TASK.txt'))
                    write_original_status(runDirectory, 'STOPPED_AT_RECORD_BOUNDARY', ...
                                          'Remove the stop file and call RUN_ORIGINAL(''resume'').');
                    write_original_report(runDirectory);
                    return
                end
                process_original_record(projectRoot, runDirectory, ...
                                        manifest(index), config, calibration);
                write_original_report(runDirectory);
            end
        end

        % 4. Summarize original results; the caller decides whether to augment.
        records = collect_record_status(runDirectory, manifest, 'all');
        if all([records.completed]) && all([records.pass])
            write_original_status(runDirectory, 'FULL_RECORD_7_3_GATE_PASSED', ...
                                  'All original records passed the fixed signal/state checks.');
        else
            write_original_status(runDirectory, 'TEST_GATE_FAILED', ...
                                  'Inspect original TEST diagnostics; no automatic retuning was applied.');
        end
        write_original_report(runDirectory);
        package_original_results(runDirectory);
    catch exception
        write_original_status(runDirectory, 'ERROR_RESUMABLE', ...
                              getReport(exception, 'extended', 'hyperlinks', 'off'));
        try
            write_original_report(runDirectory);
        catch
            % Preserve the original exception if report regeneration also fails.
        end
        rethrow(exception);
    end
end
