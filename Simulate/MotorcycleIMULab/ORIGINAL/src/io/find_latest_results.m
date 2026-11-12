function d = find_latest_results(root, part)
    % FIND_LATEST_RESULTS Resolve the latest result directory for one independent stage.
    % Inputs: root: project path; part: ORIGINAL or AUGMENTED.
    % Outputs: d: existing absolute results directory from that stage's saved pointer.

    if nargin < 2
        part = 'ORIGINAL';
    end
    base = fullfile(root, part, 'results');
    f = fullfile(base, 'LATEST_RUN.txt');
    assert(isfile(f), 'No previous %s run. Start that stage first.', part);
    name = strtrim(fileread(f));
    d = fullfile(base, name);
    assert(isfolder(d), 'Saved %s run is missing: %s', part, d);
end
