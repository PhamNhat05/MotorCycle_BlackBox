function mil_package(runDirectory)
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'C');if ~S.C.export.make_result_zip,return;end
% Full nominal outputs + videos + compact recipes. Bulk augmented CSV excluded.
f=dir(fullfile(runDirectory,'**','*'));relative={};
for k=1:numel(f)
 if f(k).isdir,continue;end
 path=fullfile(f(k).folder,f(k).name);rel=erase(path,[runDirectory filesep]);
 if contains(rel,[filesep 'augmentation' filesep]),continue;end % Root-relative case handled below.
 if startsWith(rel,['augmentation' filesep]) && endsWith(f(k).name,'.csv') && startsWith(f(k).name,'variant_'),continue;end
 if endsWith(rel,'.partial') || endsWith(rel,'.zip'),continue;end
 relative{end+1}=rel; %#ok<AGROW>
end
[parent,name]=fileparts(runDirectory);destination=fullfile(parent,[name '_REPORT.zip']);
if isfile(destination),delete(destination);end
fprintf('Packaging nominal results, videos and augmentation recipes...\n');zip(destination,relative,runDirectory);
end
