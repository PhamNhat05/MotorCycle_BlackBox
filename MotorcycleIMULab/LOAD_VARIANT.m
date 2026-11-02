function T = LOAD_VARIANT(runDirectory,parentKey,variantIndex,timeSeconds)
% Load a full or selected-time variant from its exact compact definition.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory),runDirectory=mil_latest(root);end
D=jsondecode(fileread(fullfile(runDirectory,'augmentation',parentKey,sprintf('variant_%04d.json',variantIndex))));
F=fullfile(runDirectory,'records',parentKey,'MODEL.mat');
assert(strcmp(mil_hash(F),D.parent_model_sha256),'Parent MODEL.mat was modified.');
S=load(F,'M');M=S.M;
if nargin<4 || isempty(timeSeconds),timeSeconds=M.time_source_s;end
Q=mil_query(M,timeSeconds,D.position_body_m,D.bias);
T=array2table([timeSeconds(:) Q.imu], 'VariableNames',{'Time_s','Ax_m_s2','Ay_m_s2','Az_m_s2','Gx_deg_s','Gy_deg_s','Gz_deg_s'});
end
