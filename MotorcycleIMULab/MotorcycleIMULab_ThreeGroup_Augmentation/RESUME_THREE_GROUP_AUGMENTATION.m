function outputDirectory=RESUME_THREE_GROUP_AUGMENTATION(outputDirectory)
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(outputDirectory)
 outputDirectory=uigetdir(pwd,'Select the augmentation_three_groups output folder');
 if isequal(outputDirectory,0),outputDirectory='';return;end
end
S=load(fullfile(outputDirectory,'AUGMENTATION_STATE.mat'),'A','runDirectory');
outputDirectory=tga_run(root,S.runDirectory,outputDirectory,S.A);
end
