function runDirectory = RUN_AUGMENT(originalRun, runDirectory)
    % RUN_AUGMENT Export 100 individual variants for each of ten real recordings.
    % Inputs: optional original run and optional existing augmented run to resume.
    % Output: separate AUGMENTED/results run with CSVs, individual plots and metrics.

    projectRoot = SETUP_PROJECT();
    if nargin < 1 || isempty(originalRun)
        originalRun = find_latest_results(projectRoot, 'ORIGINAL');
    end
    if nargin < 2
        runDirectory = '';
    elseif strcmpi(runDirectory, 'resume')
        runDirectory = find_latest_results(projectRoot, 'AUGMENTED');
    end
    runDirectory = generate_augmented_records( ...
                                              projectRoot, originalRun, runDirectory, AUGMENTATION_CONFIG());
end
