function R=RUN_THREE_GROUP_SELF_CHECKS()
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
R=tga_selfcheck(THREE_GROUP_CONFIG());disp(R);
end
