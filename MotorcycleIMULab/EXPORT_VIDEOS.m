function EXPORT_VIDEOS(runDirectory)
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory),runDirectory=mil_latest(root);end
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'C','manifest');
for k=1:numel(S.manifest)
 d=fullfile(runDirectory,'records',S.manifest(k).key);
 if isfile(fullfile(d,'MODEL.mat'))
  try, mil_video(d,S.C); catch e, warning('%s: %s',S.manifest(k).key,e.message);end
 end
end
mil_report(runDirectory); mil_package(runDirectory);
end
