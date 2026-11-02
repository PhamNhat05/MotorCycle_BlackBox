function d=mil_latest(root)
f=fullfile(root,'results','LATEST_RUN.txt');assert(isfile(f),'Run RUN_PROJECT first.');
d=strtrim(fileread(f));assert(isfolder(d),'The saved run directory has moved. Pass its current path explicitly.');
end
