function A=mil_read(root,item)
file=fullfile(root,item.relative_path);assert(isfile(file),'Missing input: %s',file);
assert(strcmp(mil_hash(file),item.sha256),'Input checksum changed: %s',item.key);
fid=fopen(file,'rt','n','ISO-8859-1');assert(fid>=0);cl=onCleanup(@()fclose(fid));
S=textscan(fid,'%f%f%f%f%f%f%f','HeaderLines',1,'CollectOutput',true);
A=S{1};assert(size(A,2)==7 && size(A,1)==item.samples,'Unexpected input shape: %s',item.key);
assert(all(isfinite(A(:))) && all(diff(A(:,1))>0),'Invalid input samples.');
assert(max(abs(diff(A(:,1))-0.001))<1e-7,'Expected a complete 1000 Hz record.');
end
