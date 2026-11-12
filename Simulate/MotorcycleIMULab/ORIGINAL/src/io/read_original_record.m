function A = read_original_record(root, item)
    % READ_ORIGINAL_RECORD Read an unchanged Latin-1, tab-separated source recording.
    % Inputs: root: project path; item: manifest row with path, checksum and expected samples.
    % Outputs: A: [time_s Ax Ay Az Gx Gy Gz]; all 1 ms samples and startup zeros are retained.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    file = fullfile(root, item.relative_path);
    assert(isfile(file), 'Missing input: %s', file);
    assert(strcmp(hash_file(file), item.sha256), 'Input checksum changed: %s', item.key);
    fid = fopen(file, 'rt', 'n', 'ISO-8859-1');
    assert(fid >= 0);
    cl = onCleanup(@()fclose(fid));
    S = textscan(fid, '%f%f%f%f%f%f%f', 'HeaderLines', 1, 'CollectOutput', true);
    A = S{1};
    assert(size(A, 2) == 7 && size(A, 1) == item.samples, 'Unexpected input shape: %s', item.key);
    assert(all(isfinite(A(:))) && all(diff(A(:, 1)) > 0), 'Invalid input samples.');
    assert(max(abs(diff(A(:, 1)) - 0.001)) < 1e-7, 'Expected a complete 1000 Hz record.');
end
