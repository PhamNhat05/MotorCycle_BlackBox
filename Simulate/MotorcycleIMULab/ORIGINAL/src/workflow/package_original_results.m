function package_original_results(runDirectory)
    % PACKAGE_ORIGINAL_RESULTS Package only the original-stage outputs when configured.
    % Inputs: runDirectory: completed or interrupted ORIGINAL results session.
    % Outputs: A ZIP beside that session; augmentation remains in its separate directory.

    S = load(fullfile(runDirectory, 'RUN_STATE.mat'), 'C');
    if ~S.C.export.make_result_zip
        return
    end
    entries = dir(fullfile(runDirectory, '**', '*'));
    relative = {};
    for k = 1:numel(entries)
        if entries(k).isdir || contains(entries(k).name, '.partial') || endsWith(entries(k).name, '.zip')
            continue
        end
        relative{end + 1} = erase(fullfile(entries(k).folder, entries(k).name), [runDirectory filesep]); %#ok<AGROW>
    end
    [parent, name] = fileparts(runDirectory);
    destination = fullfile(parent, [name '_ORIGINAL_RESULTS.zip']);
    if isfile(destination)
        delete(destination);
    end
    fprintf('Packaging ORIGINAL signal/state/plot results...\n');
    zip(destination, relative, runDirectory);
end
