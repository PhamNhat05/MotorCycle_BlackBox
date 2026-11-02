function h=mil_hash(file)
fid=fopen(file,'rb');assert(fid>=0,'Cannot read %s',file);cl=onCleanup(@()fclose(fid));
m=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid),b=fread(fid,1048576,'*uint8');if ~isempty(b),m.update(typecast(b,'int8'));end,end
b=typecast(m.digest(),'uint8');h=lower(reshape(dec2hex(b,2)',1,[]));
end
