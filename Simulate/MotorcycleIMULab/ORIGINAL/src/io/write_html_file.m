function write_html_file(path, html)
    % WRITE_HTML_FILE Atomically write a complete standalone UTF-8 report page.
    directory = fileparts(path);
    if ~isfolder(directory)
        mkdir(directory);
    end
    temporary = [path '.partial'];
    file = fopen(temporary, 'w');
    assert(file >= 0, 'Cannot write HTML report: %s', path);
    cleanup = onCleanup(@() fclose(file));
    fwrite(file, unicode2native(html, 'UTF-8'), 'uint8');
    clear cleanup;
    movefile(temporary, path, 'f');
end
