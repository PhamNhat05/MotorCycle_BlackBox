function runDirectory = RESUME_PROJECT(runDirectory)
% Resume completed tasks without changing the saved scientific configuration.
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory), runDirectory=mil_latest(root); end
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'C');
runDirectory=mil_run(root,S.C,runDirectory);
end
