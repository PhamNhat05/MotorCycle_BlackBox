function outputDirectory=RUN_THREE_GROUP_AUGMENTATION(runDirectory,outputDirectory)
% Choose the existing RUN folder containing RUN_STATE.mat and records/.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'matlab'));
if nargin<1 || isempty(runDirectory)
 runDirectory=uigetdir(pwd,'Select the completed MotorcycleIMULab RUN folder');
 if isequal(runDirectory,0),outputDirectory='';return;end
end
if nargin<2 || isempty(outputDirectory),outputDirectory=fullfile(runDirectory,'augmentation_three_groups');end
outputDirectory=tga_run(root,runDirectory,outputDirectory,THREE_GROUP_CONFIG());
end
