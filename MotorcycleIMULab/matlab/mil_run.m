function runDirectory=mil_run(root,C,runDirectory)
manifest=jsondecode(fileread(fullfile(root,'config','INPUT_MANIFEST.json')));
assert(sum(strcmp({manifest.split},'build'))==7 && sum(strcmp({manifest.split},'test'))==3);
assert(numel(unique({manifest.key}))==10,'BUILD/TEST overlap.');
codeManifest=mil_code_manifest(root);
if isempty(runDirectory)
 runDirectory=fullfile(root,'results',['RUN_' datestr(now,'yyyymmdd_HHMMSS_FFF')]);mkdir(runDirectory);
 save(fullfile(runDirectory,'RUN_STATE.mat'),'C','manifest','codeManifest');mil_json(fullfile(runDirectory,'DECLARED_SETTINGS.json'),C);
 writetable(codeManifest,fullfile(runDirectory,'CODE_SHA256.csv'));
 copyfile(fullfile(root,'docs'),fullfile(runDirectory,'documentation'));
 copyfile(fullfile(root,'OBJECTIVES.md'),fullfile(runDirectory,'documentation','OBJECTIVES.md'));
 copyfile(fullfile(root,'config','INPUT_MANIFEST.json'),fullfile(runDirectory,'INPUT_MANIFEST.json'));
 fid=fopen(fullfile(root,'results','LATEST_RUN.txt'),'w');fprintf(fid,'%s\n',runDirectory);fclose(fid);
else
 S=load(fullfile(runDirectory,'RUN_STATE.mat'));
 assert(isequal(S.C,C) && isequal(S.manifest,manifest),'Saved configuration or inputs changed. Start a new run.');
 assert(isequal(S.codeManifest,codeManifest),'Project code changed. Start a new run to preserve the frozen protocol.');
end
for inputIndex=1:numel(manifest)
 assert(strcmp(mil_hash(fullfile(root,manifest(inputIndex).relative_path)),manifest(inputIndex).sha256),'Input bytes changed: %s',manifest(inputIndex).key);
end
fprintf('\nMotorcycleIMULab | FULL RECORD | 7 BUILD + 3 TEST | no timed pauses\nResults: %s\n',runDirectory);
diary(fullfile(runDirectory,'RUN_LOG.txt'));dc=onCleanup(@()diary('off'));
try
 checks=mil_selfcheck();mil_json(fullfile(runDirectory,'MATLAB_SELF_CHECKS.json'),checks);
 if isfile(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat'))
  S=load(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat'),'K');K=S.K;
  assert(strcmp(mil_hash(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat')),strtrim(fileread(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.sha256')))),'Candidate calibration changed.');
 else
  fprintf('Estimating shared gyro prior from seven BUILD prefixes only...\n');K=mil_calibrate(root,C,manifest);
  save(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat'),'K');
  fid=fopen(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.sha256'),'w');fprintf(fid,'%s\n',mil_hash(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat')));fclose(fid);
  mil_json(fullfile(runDirectory,'CANDIDATE_CONFIGURATION.json'),struct('C',C,'K',K));
 end
 for phase={'build','test'}
  split=phase{1};
  if strcmp(split,'test')
   B=mil_collect(runDirectory,manifest,'build');
   if ~all([B.pass]),mil_status(runDirectory,'BUILD_GATE_FAILED_TEST_NOT_OPENED','Review all seven BUILD diagnostics. No automatic tuning or augmentation.');mil_report(runDirectory);mil_package(runDirectory);return;end
   lock=fullfile(runDirectory,'FROZEN_CONFIGURATION.json');
   if ~isfile(lock)
    mil_json(lock,struct('C',C,'K',K,'build_gate_pass',true,'test_values_used_for_common_configuration',false,'frozen_at',datestr(now,30)));
    hash=mil_hash(lock);fid=fopen(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256'),'w');fprintf(fid,'%s\n',hash);fclose(fid);
   end
   assert(strcmp(mil_hash(lock),strtrim(fileread(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256')))),'Frozen configuration changed.');
   frozen=jsondecode(fileread(lock));assert(isequaln(frozen.K,jsondecode(jsonencode(K))) && isequaln(frozen.C,jsondecode(jsonencode(C))),'Candidate differs from frozen configuration.');
   fprintf('Shared configuration FROZEN. Opening three conditional TEST reconstructions.\n');
  end
  ids=find(strcmp({manifest.split},split));
  for j=1:numel(ids)
   item=manifest(ids(j));directory=fullfile(runDirectory,'records',item.key);quality=fullfile(directory,'QUALITY.json');
   if isfile(fullfile(runDirectory,'STOP_AFTER_CURRENT_TASK.txt')),mil_status(runDirectory,'STOPPED_AT_TASK_BOUNDARY','Remove STOP_AFTER_CURRENT_TASK.txt, then call RESUME_PROJECT.');mil_report(runDirectory);mil_package(runDirectory);return;end
   if ~isfile(quality)
    fprintf('\n%s %d/%d | %s | %d samples | %.3f to %.3f s\n',upper(split),j,numel(ids),item.key,item.samples,item.first_time_s,item.last_time_s);
    taskClock=tic;A=mil_read(root,item);M=mil_reconstruct(A,C,K,item);[T,D]=mil_metrics(A,M,C);D.reconstruction_elapsed_s=toc(taskClock);
    mil_export_record(directory,A,M,C,T,D);fprintf('  Full-record gate: %s | six-axis fit written\n',string(D.pass));
    clear A M T D;
   else
    fprintf('Using completed record: %s\n',item.key);
   end
   mil_report(runDirectory);
   if C.video.enabled
    try,mil_video(directory,C);catch e,warning('Video export failed for %s: %s. Use EXPORT_VIDEOS after fixing graphics.',item.key,e.message);end
   end
  end
 end
 allRecords=mil_collect(runDirectory,manifest,'all');
 if all([allRecords.pass])
  mil_status(runDirectory,'FULL_RECORD_7_3_GATE_PASSED','Conditional six-axis reconstruction passed. External trajectory accuracy remains unvalidated.');
  if C.augmentation.enabled,mil_augment(runDirectory,C);end
 else
  mil_status(runDirectory,'TEST_GATE_FAILED_AUGMENTATION_BLOCKED','No TEST-driven automatic retuning. Inspect per-axis reports.');
 end
 mil_report(runDirectory);mil_package(runDirectory);
 fprintf('\nFinished current workflow. Open REPORT.html and STATUS.json.\n');
catch e
 mil_status(runDirectory,'ERROR_RESUMABLE',getReport(e,'extended','hyperlinks','off'));
 try,mil_report(runDirectory);mil_package(runDirectory);catch,end
 fprintf(2,'\nStopped: %s\nResume with RESUME_PROJECT after resolving the cause.\n',e.message);rethrow(e);
end
end
function mil_status(d,status,message)
mil_json(fullfile(d,'STATUS.json'),struct('status',status,'message',message,'updated_at',datestr(now,30)));
end
