function mil_json(file,value)
parent=fileparts(file);if ~isfolder(parent),mkdir(parent);end
try,s=jsonencode(value,'PrettyPrint',true);catch,s=jsonencode(value);end
tmp=[file '.partial'];fid=fopen(tmp,'w','n','UTF-8');assert(fid>=0,'Cannot write %s',file);
fwrite(fid,s,'char');fwrite(fid,newline,'char');fclose(fid);movefile(tmp,file,'f');
end
