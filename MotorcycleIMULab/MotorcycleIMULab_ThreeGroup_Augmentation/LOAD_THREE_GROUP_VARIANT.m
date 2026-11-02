function T=LOAD_THREE_GROUP_VARIANT(outputDirectory,groupName,parentKey,variantIndex,timeSeconds)
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
S=load(fullfile(outputDirectory,'AUGMENTATION_STATE.mat'),'runDirectory');
D=jsondecode(fileread(fullfile(outputDirectory,groupName,parentKey,sprintf('variant_%04d.json',variantIndex))));
f=fullfile(S.runDirectory,'records',parentKey,'MODEL.mat');assert(strcmp(mil_hash(f),D.parent_model_sha256),'Parent model changed.');
Z=load(f,'M');M=Z.M;if nargin<5 || isempty(timeSeconds),timeSeconds=M.time_source_s;end
Q=mil_query(M,timeSeconds,D.position_body_m,D.bias);
T=array2table([timeSeconds(:) Q.imu],'VariableNames',{'Time_s','Ax_m_s2','Ay_m_s2','Az_m_s2','Gx_deg_s','Gy_deg_s','Gz_deg_s'});
end
