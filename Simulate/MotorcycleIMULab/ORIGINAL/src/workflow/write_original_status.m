function write_original_status(runDirectory, state, message)
    % WRITE_ORIGINAL_STATUS Record original-stage progress in a small JSON file.
    write_json(fullfile(runDirectory, 'STATUS.json'), ...
               struct('status', state, 'message', message, 'updated_at', datestr(now, 30)));
end
