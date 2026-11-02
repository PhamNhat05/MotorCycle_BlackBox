function EXPORT_AUGMENTED_DATA(runDirectory,exportMode)
% Resume/export all variants. Only this export setting may be overridden.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory),runDirectory=mil_latest(root);end
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'C');C=S.C;
if nargin>=2,C.augmentation.export_mode=exportMode;end
mil_augment(runDirectory,C);mil_report(runDirectory);mil_package(runDirectory);
end
