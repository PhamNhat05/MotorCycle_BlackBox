function outputs = RUN_ALL(mode)
    % RUN_ALL Execute originals first, then augment after all ten original gates pass.
    % Input: optional 'resume' continues the latest compatible results sessions.
    % Output: structure containing separate original and augmented directory paths.

    projectRoot = SETUP_PROJECT();
    if nargin < 1
        mode = 'new';
    end
    assert(any(strcmpi(mode, {'new', 'resume'})), 'Use RUN_ALL or RUN_ALL(''resume'').');
    if strcmpi(mode, 'resume')
        originalRun = RUN_ORIGINAL('resume');
    else
        originalRun = RUN_ORIGINAL();
    end
    outputs = struct('original', originalRun, 'augmented', '');

    state = load(fullfile(originalRun, 'RUN_STATE.mat'), 'manifest');
    records = collect_record_status(originalRun, state.manifest, 'all');
    if ~all([records.completed]) || ~all([records.pass])
        fprintf('Original records are unfinished or failed. Inspect ORIGINAL results.\n');
        return
    end

    % Continue augmentation only when the saved source-session name matches.
    previousAugmented = '';
    pointer = fullfile(projectRoot, 'AUGMENTED', 'results', 'LATEST_RUN.txt');
    if strcmpi(mode, 'resume') && isfile(pointer)
        candidate = find_latest_results(projectRoot, 'AUGMENTED');
        saved = load(fullfile(candidate, 'AUGMENT_STATE.mat'), 'original_run_name');
        [~, originalName] = fileparts(originalRun);
        if strcmp(saved.original_run_name, originalName)
            previousAugmented = candidate;
        end
    end
    outputs.augmented = RUN_AUGMENT(originalRun, previousAugmented);
    fprintf('\nORIGINAL: %s\nAUGMENTED: %s\n', outputs.original, outputs.augmented);
    fprintf('Open REPORT.html for originals and INDEX.html for augmented variants.\n');
end
