function runDirectory = RUN_ORIGINAL(runDirectory)
    % RUN_ORIGINAL Process all original recordings without launching augmentation.
    % Input: optional existing results path, or resume to use the latest session.
    % Output: run directory containing models, full signals, states, plots and fits.

    projectRoot = SETUP_PROJECT();
    if nargin < 1
        runDirectory = '';
    elseif strcmpi(runDirectory, 'resume')
        runDirectory = find_latest_results(projectRoot, 'ORIGINAL');
    end
    runDirectory = process_original_records(projectRoot, ORIGINAL_CONFIG(), runDirectory);
end
