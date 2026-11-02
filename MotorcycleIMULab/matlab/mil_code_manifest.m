function T=mil_code_manifest(root)
f=[dir(fullfile(root,'*.m'));dir(fullfile(root,'matlab','*.m'))];names=cell(numel(f),1);hashes=names;
for k=1:numel(f),names{k}=strrep(fullfile(f(k).folder,f(k).name),[root filesep],'');hashes{k}=mil_hash(fullfile(f(k).folder,f(k).name));end
T=table(names,hashes,'VariableNames',{'RelativePath','SHA256'});T=sortrows(T,'RelativePath');
end
