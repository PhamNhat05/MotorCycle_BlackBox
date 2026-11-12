function freeze_original_configuration(runDirectory, config, calibration, manifest)
    % FREEZE_ORIGINAL_CONFIGURATION Lock the shared settings before opening TEST.
    % Preconditions: every BUILD record is complete and passes its fixed gates.

    records = collect_record_status(runDirectory, manifest, 'build');
    assert(all([records.completed]) && all([records.pass]), ...
           'All seven BUILD records must pass before freezing the configuration.');
    lock = fullfile(runDirectory, 'FROZEN_CONFIGURATION.json');
    if ~isfile(lock)
        frozen = struct('C', config, 'K', calibration, 'build_gate_pass', true, ...
                        'test_values_used_for_common_configuration', false, ...
                        'frozen_at', datestr(now, 30));
        write_json(lock, frozen);
        file = fopen([lock '.sha256'], 'w');
        assert(file >= 0, 'Cannot write the frozen-configuration checksum.');
        fprintf(file, '%s\n', hash_file(lock));
        fclose(file);
    end

    assert(strcmp(hash_file(lock), strtrim(fileread([lock '.sha256']))), ...
           'The frozen original configuration changed.');
    frozen = jsondecode(fileread(lock));
    assert(isequaln(frozen.K, jsondecode(jsonencode(calibration))) && ...
           isequaln(frozen.C, jsondecode(jsonencode(config))), ...
           'Current settings differ from the frozen original settings.');
end
