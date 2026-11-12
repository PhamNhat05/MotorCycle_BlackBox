function records = collect_record_status(runDirectory, manifest, split)
    % COLLECT_RECORD_STATUS Read completion and pass/fail flags without changing result files.
    % Inputs: runDirectory: original results path; manifest: records; split: build/test/all.
    % Outputs: records: source keys, original split, completion flags and gate results.

    if strcmp(split, 'all')
        ids = 1:numel(manifest);
    else
        ids = find(strcmp({manifest.split}, split));
    end
    records = repmat(struct('key', '', 'split', '', 'completed', false, 'pass', false), numel(ids), 1);
    for j = 1:numel(ids)
        item = manifest(ids(j));
        records(j).key = item.key;
        records(j).split = item.split;
        file = fullfile(runDirectory, 'records', item.key, 'QUALITY.json');
        if isfile(file)
            D = jsondecode(fileread(file));
            records(j).completed = true;
            records(j).pass = D.pass;
        end
    end
end
