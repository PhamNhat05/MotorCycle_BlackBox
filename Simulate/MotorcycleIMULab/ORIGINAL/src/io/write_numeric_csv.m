function write_numeric_csv(file, names, X)
    % WRITE_NUMERIC_CSV Stream a full numeric matrix to an atomic CSV output.
    % Inputs: file: destination; names: column headers; X: all rows without decimation.
    % Outputs: A complete CSV with ten significant digits; failed temporary files are not committed.

    % Streaming-friendly numeric CSV, ten significant digits, no spreadsheet toolbox.
    fid = fopen([file '.partial'], 'w');
    assert(fid >= 0, 'Cannot write %s', file);
    cl = onCleanup(@()fclose(fid));
    fprintf(fid, '%s\n', strjoin(names, ','));
    fmt = [repmat('%.10g,', 1, size(X, 2) - 1) '%.10g\n'];
    for k = 1:10000:size(X, 1)
        ix = k:min(size(X, 1), k + 9999);
        fprintf(fid, fmt, X(ix, :)');
    end
    clear cl;
    movefile([file '.partial'], file, 'f');
end
