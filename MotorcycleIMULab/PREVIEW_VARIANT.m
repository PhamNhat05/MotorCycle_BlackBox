function PREVIEW_VARIANT(runDirectory,parentKey,variantIndex)
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory),runDirectory=mil_latest(root);end
if nargin<2,parentKey='fall_curve';end
if nargin<3,variantIndex=1;end
S=load(fullfile(runDirectory,'records',parentKey,'MODEL.mat'),'M');M=S.M;
D=jsondecode(fileread(fullfile(runDirectory,'augmentation',parentKey,sprintf('variant_%04d.json',variantIndex))));
assert(strcmp(mil_hash(fullfile(runDirectory,'records',parentKey,'MODEL.mat')),D.parent_model_sha256),'Parent model changed.');
C=PROJECT_CONFIG(); C.video.enabled=true;
mil_video(fullfile(runDirectory,'records',parentKey),C,M,D);
end
