function report = RUN_SELF_CHECKS()
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'matlab'));
report=mil_selfcheck(); disp(report);
end
