function projectRoot = SETUP_PROJECT()
    % SETUP_PROJECT Register this project's source directories and result folders.
    % Output: absolute project root. Data and generated results are not added to PATH.

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(projectRoot, ...
            fullfile(projectRoot, 'ORIGINAL'), ...
            fullfile(projectRoot, 'AUGMENTED'), ...
            genpath(fullfile(projectRoot, 'ORIGINAL', 'src')), ...
            genpath(fullfile(projectRoot, 'AUGMENTED', 'src')), '-begin');

    for stage = {'ORIGINAL', 'AUGMENTED'}
        resultsDirectory = fullfile(projectRoot, stage{1}, 'results');
        if ~isfolder(resultsDirectory)
            mkdir(resultsDirectory);
        end
    end
end
