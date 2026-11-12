function manifest = create_code_manifest(projectRoot, stage)
    % CREATE_CODE_MANIFEST Hash the source files that determine a stage's results.
    % Inputs: project root and 'original' or 'augmented'. Output: sorted hash table.
    % Augmentation-only changes do not invalidate completed original-stage runs.

    if nargin < 2
        stage = 'original';
    end
    files = [dir(fullfile(projectRoot, 'ORIGINAL', 'src', '**', '*.m')); ...
             dir(fullfile(projectRoot, 'SETUP_PROJECT.m'))];
    if strcmp(stage, 'original')
        files = [files; ...
                 dir(fullfile(projectRoot, 'ORIGINAL', 'ORIGINAL_CONFIG.m')); ...
                 dir(fullfile(projectRoot, 'RUN_ORIGINAL.m'))];
    else
        assert(strcmp(stage, 'augmented'), 'Unknown stage: %s', stage);
        files = [files; ...
                 dir(fullfile(projectRoot, 'AUGMENTED', 'AUGMENTATION_CONFIG.m')); ...
                 dir(fullfile(projectRoot, 'AUGMENTED', 'src', '**', '*.m')); ...
                 dir(fullfile(projectRoot, 'RUN_AUGMENT.m'))];
    end

    names = cell(numel(files), 1);
    hashes = names;
    for index = 1:numel(files)
        absolutePath = fullfile(files(index).folder, files(index).name);
        names{index} = strrep(erase(absolutePath, [projectRoot filesep]), filesep, '/');
        hashes{index} = hash_file(absolutePath);
    end
    manifest = sortrows(table(names, hashes, ...
                              'VariableNames', {'RelativePath', 'SHA256'}), 'RelativePath');
end
