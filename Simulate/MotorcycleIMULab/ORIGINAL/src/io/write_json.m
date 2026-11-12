function write_json(file, value)
    % WRITE_JSON Atomically write structured metadata as JSON.
    % Inputs: file: output path; value: MATLAB struct, array or table-compatible metadata.
    % Outputs: A complete JSON file, replacing its temporary .partial file on success.

    parent = fileparts(file);
    if ~isfolder(parent)
        mkdir(parent);
    end
    try
        s = jsonencode(value, 'PrettyPrint', true);
    catch
        s = jsonencode(value);
    end
    tmp = [file '.partial'];
    fid = fopen(tmp, 'w', 'n', 'UTF-8');
    assert(fid >= 0, 'Cannot write %s', file);
    fwrite(fid, s, 'char');
    fwrite(fid, newline, 'char');
    fclose(fid);
    movefile(tmp, file, 'f');
end
