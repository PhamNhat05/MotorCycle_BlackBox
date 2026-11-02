function outputDirectory=tga_run(root,runDirectory,outputDirectory,A)
assert(isfile(fullfile(runDirectory,'RUN_STATE.mat')),'Select the RUN folder containing RUN_STATE.mat.');
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'manifest');manifest=S.manifest;
assert(numel(manifest)==10 && numel(unique({manifest.key}))==10,'Expected all ten parent records.');
assert(sum(strcmp({manifest.split},'build'))==7 && sum(strcmp({manifest.split},'test'))==3,'Expected the frozen 7:3 reconstruction split.');
allAIKeys=[A.ai_proposal.train A.ai_proposal.validation A.ai_proposal.test];assert(isequal(sort(allAIKeys),sort({manifest.key})),'AI proposal keys do not match the source parents.');
testIds=find(strcmp({manifest.split},'test'));assert(isequal(sort(A.ai_proposal.test),sort({manifest(testIds).key})),'The original three TEST parents must stay held out.');
lock=fullfile(runDirectory,'FROZEN_CONFIGURATION.json');assert(isfile(lock),'Common reconstruction configuration was not frozen.');
frozenHash=mil_hash(lock);assert(strcmp(frozenHash,strtrim(fileread(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256')))),'Frozen configuration changed.');
F=jsondecode(fileread(lock));old=F.C.augmentation;
assert(all(A.acc_bias_delta_bound_m_s2(:)<=old.acc_bias_delta_bound_m_s2(:)+eps) && all(A.gyro_bias_delta_bound_deg_s(:)<=old.gyro_bias_delta_bound_deg_s(:)+eps) && all(A.position_delta_bound_body_m(:)<=old.position_delta_bound_body_m(:)+eps),'Requested perturbations exceed the frozen experimental bounds.');
assert(ismember(A.export_mode,{'full_csv','compact'}));
checks=tga_selfcheck(A);sourceHashes=cell(10,1);
for p=1:10
 item=manifest(p);d=fullfile(runDirectory,'records',item.key);assert(isfile(fullfile(d,'QUALITY.json')),'A parent record is unfinished: %s',item.key);
 D=jsondecode(fileread(fullfile(d,'QUALITY.json')));assert(D.pass && D.full_record && D.excluded_samples==0 && D.scored_samples==item.samples,'Full-record gate failed: %s',item.key);
 assert(isfile(fullfile(d,'MODEL.mat')),'Missing full model for %s',item.key);sourceHashes{p}=mil_hash(fullfile(d,'MODEL.mat'));
end
codeFiles=[dir(fullfile(root,'*.m'));dir(fullfile(root,'matlab','*.m'))];codeNames=cell(numel(codeFiles),1);codeHashes=codeNames;
for k=1:numel(codeFiles),codeNames{k}=strrep(fullfile(codeFiles(k).folder,codeFiles(k).name),[root filesep],'');codeHashes{k}=mil_hash(fullfile(codeFiles(k).folder,codeFiles(k).name));end
code=sortrows(table(codeNames,codeHashes),1);
stateFile=fullfile(outputDirectory,'AUGMENTATION_STATE.mat');
if isfolder(outputDirectory) && ~isfile(stateFile)
 existing=dir(outputDirectory);existing=existing(~ismember({existing.name},{'.','..'}));assert(isempty(existing),'Use an empty output directory or this exporter''s existing output folder.');
end
if ~isfolder(outputDirectory),mkdir(outputDirectory);end
if isfile(stateFile)
 previous=load(stateFile);assert(isequaln(previous.A,A) && isequaln(previous.manifest,manifest) && isequaln(previous.sourceHashes,sourceHashes) && strcmp(previous.frozenHash,frozenHash) && isequal(previous.code,code),'Augmentation settings, source models or code changed. Use a new output directory.');
else
 save(stateFile,'A','manifest','sourceHashes','frozenHash','runDirectory','code');mil_json(fullfile(outputDirectory,'SETTINGS.json'),A);
 copyfile(fullfile(root,'docs'),fullfile(outputDirectory,'documentation'));copyfile(fullfile(root,'README.md'),fullfile(outputDirectory,'documentation','README.md'));
end
mil_json(fullfile(outputDirectory,'MATLAB_SELF_CHECKS.json'),checks);
groups={'bias_only','position_only','bias_and_position'};counts=[A.counts.bias_only A.counts.position_only A.counts.bias_and_position];total=10*sum(counts);
plan=[];n=0;neededRows=0;
for p=1:10
 item=manifest(p);Z=load(fullfile(runDirectory,'records',item.key,'MODEL.mat'),'M');M=Z.M;
 assert(numel(M.time_source_s)==item.samples && size(M.measured_imu,1)==item.samples,'Parent is not full length.');
 assert(max(abs(reshape(M.K.bias,1,6)-reshape(F.K.bias,1,6)))<1e-12 && max(abs(M.K.sensor_to_body-F.K.sensor_to_body),[],'all')<1e-12 && max(abs(reshape(M.K.nominal_position_body_m,1,3)-reshape(F.K.nominal_position_body_m,1,3)))<1e-12,'Parent configuration differs from the frozen configuration.');
 if ismember(item.key,A.ai_proposal.train),role='train';elseif ismember(item.key,A.ai_proposal.validation),role='validation';else,role='test';end
 calibrationKeys=cellstr(string(M.K.build_keys));assert(isempty(intersect(calibrationKeys,A.ai_proposal.test)),'Original TEST parents were used for shared calibration; the holdout protocol is invalid.');strictCalibration=isempty(intersect(calibrationKeys,[A.ai_proposal.validation A.ai_proposal.test]));
 for g=1:3
  group=groups{g};stream=RandStream('mt19937ar','Seed',A.seed+100*p+g);[db,dr]=tga_draw(stream,group,counts(g),A);
  d=fullfile(outputDirectory,group,item.key);if ~isfolder(d),mkdir(d);end
  for v=1:counts(g)
   relative=fullfile(group,item.key,sprintf('variant_%04d.csv',v));file=fullfile(outputDirectory,relative);
   D=struct('schema',1,'group',group,'parent_key',item.key,'parent_reconstruction_split',item.split,'suggested_ai_role',role,'strict_ai_generator_calibration_train_only',strictCalibration,'holdout_stress_only',strcmp(item.split,'test'),'variant_index',v,'parent_model_sha256',sourceHashes{p},'frozen_configuration_sha256',frozenHash,'bias_delta',db(v,:),'position_delta_body_m',dr(v,:),'bias',M.K.bias+db(v,:),'position_body_m',M.K.nominal_position_body_m+dr(v,:),'samples',item.samples,'first_source_s',M.time_source_s(1),'last_source_s',M.time_source_s(end),'record_contains_fall',item.record_contains_fall,'reference_contact_start_s',item.reference_contact_start_s,'reference_contact_end_s',item.reference_contact_end_s,'scope','SAME_LATENT_MOTION_SENSOR_PERTURBATION_NOT_NEW_PHYSICAL_FALL','data_edition_verified_against_corrigendum',false,'bounds_hardware_validated',false,'relative_csv_path',strrep(relative,filesep,'/'));
   definition=strrep(file,'.csv','.json');
   if isfile(definition),assert(isequaln(jsondecode(fileread(definition)),jsondecode(jsonencode(D))),'Existing definition changed.');else,mil_json(definition,D);end
   done=isfile(file) && isfile([file '.complete.json']);if ~done,neededRows=neededRows+item.samples;end
   entry=struct('ParentKey',item.key,'Group',group,'VariantIndex',v,'Samples',item.samples,'ReconstructionSplit',item.split,'SuggestedAIRole',role,'StrictTrainOnlyGeneratorCalibration',strictCalibration,'HoldoutStressOnly',strcmp(item.split,'test'),'DeltaAx',db(v,1),'DeltaAy',db(v,2),'DeltaAz',db(v,3),'DeltaGx',db(v,4),'DeltaGy',db(v,5),'DeltaGz',db(v,6),'DeltaX_m',dr(v,1),'DeltaY_m',dr(v,2),'DeltaZ_m',dr(v,3),'Materialized',done,'RelativeCSV',strrep(relative,filesep,'/'));
   n=n+1;if isempty(plan),plan=entry;else,plan(n)=entry;end
  end
 end
end
assert(n==total);tga_index(outputDirectory,plan,manifest,A);
if strcmp(A.export_mode,'compact')
 tga_status(outputDirectory,'COMPACT_RECIPES_COMPLETE',total,sum([plan.Materialized]),'Definitions only. Full CSV files have not all been materialized.');return;
end
required=neededRows*A.estimated_csv_bytes_per_row+A.disk_reserve_gb*1e9;disk=java.io.File(outputDirectory);free=double(disk.getUsableSpace());
if free>0 && free<required
 tga_status(outputDirectory,'PENDING_DISK_SPACE',total,sum([plan.Materialized]),sprintf('Approximately %.1f GB free required; %.1f GB available. Resume after freeing space.',required/1e9,free/1e9));return;
end
try
 for p=1:10
  item=manifest(p);Z=load(fullfile(runDirectory,'records',item.key,'MODEL.mat'),'M');M=Z.M;Q=mil_query(M,M.time_source_s);N=numel(M.time_source_s);
  realDir=fullfile(outputDirectory,'real_measured',item.split);if ~isfolder(realDir),mkdir(realDir);end
  f=fullfile(realDir,[item.key '.csv']);if ~isfile(f),mil_writecsv(f,{'Time_s','Ax_m_s2','Ay_m_s2','Az_m_s2','Gx_deg_s','Gy_deg_s','Gz_deg_s'},[M.time_source_s M.measured_imu]);end
  selected=find(strcmp({plan.ParentKey},item.key));
  for z=reshape(selected,1,[])
   if isfile(fullfile(outputDirectory,'STOP_AFTER_CURRENT_FILE.txt'))
    tga_status(outputDirectory,'STOPPED_AT_FILE_BOUNDARY',total,sum([plan.Materialized]),'Remove STOP_AFTER_CURRENT_FILE.txt, then RESUME_THREE_GROUP_AUGMENTATION.');return;
   end
   file=fullfile(outputDirectory,plan(z).RelativeCSV);sidecar=[file '.complete.json'];
   if plan(z).Materialized
    done=jsondecode(fileread(sidecar));assert(strcmp(mil_hash(file),done.sha256),'An exported variant was modified: %s',file);continue;
   end
   D=jsondecode(fileread(strrep(file,'.csv','.json')));tmp=[file '.partial'];fid=fopen(tmp,'w');assert(fid>=0,'Cannot write %s',tmp);
   fprintf(fid,'Time_s,Ax_m_s2,Ay_m_s2,Az_m_s2,Gx_deg_s,Gy_deg_s,Gz_deg_s\n');maxError=0;maxAbs=zeros(1,6);maxChange=zeros(1,6);db=reshape(D.bias_delta,1,6);dr=reshape(D.position_delta_body_m,1,3);
   try
    for start=1:A.chunk_rows:N
     ids=start:min(N,start+A.chunk_rows-1);rr=repmat(dr,numel(ids),1);w=Q.omega_body_rad_s(ids,:);alpha=Q.alpha_body_rad_s2(ids,:);
     deltaAcc=(cross(alpha,rr,2)+cross(w,cross(w,rr,2),2))*M.K.sensor_to_body;
     Y=Q.imu(ids,:)+[deltaAcc zeros(numel(ids),3)]+db;
     assert(all(isfinite(Y),'all'),'Nonfinite variant output.');
     if strcmp(D.group,'position_only'),assert(max(abs(Y(:,4:6)-Q.imu(ids,4:6)),[],'all')<1e-12,'Fixed-position translation must not change gyro.');end
     pick=unique(round(linspace(1,numel(ids),min(3,numel(ids)))));exact=mil_query(M,M.time_source_s(ids(pick)),D.position_body_m,D.bias);
     maxError=max(maxError,max(abs(exact.imu-Y(pick,:)),[],'all'));assert(maxError<1e-6,'Forward sensor consistency failed.');
     maxAbs=max(maxAbs,max(abs(Y),[],1));maxChange=max(maxChange,max(abs(Y-Q.imu(ids,:)),[],1));
     fprintf(fid,'%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n',[M.time_source_s(ids) Y]');
    end
    fclose(fid);
   catch e,fclose(fid);rethrow(e);end
   movefile(tmp,file,'f');mil_json(sidecar,struct('samples',N,'sha256',mil_hash(file),'finite',true,'forward_consistency_max_abs',maxError,'axis_max_abs',maxAbs,'axis_max_change_from_nominal',maxChange,'hardware_range_verified',false));
   plan(z).Materialized=true;writetable(struct2table(plan),fullfile(outputDirectory,'VARIANT_MANIFEST.csv'));
   fprintf('%d/%d | %s | %s | %d full-record rows\n',sum([plan.Materialized]),total,item.key,D.group,N);
  end
 end
 tga_index(outputDirectory,plan,manifest,A);tga_status(outputDirectory,'FULL_CSV_EXPORT_COMPLETE',total,sum([plan.Materialized]),'All requested synthetic full-record CSVs exported. Real TEST files remain the main evaluation set; TEST descendants are stress tests only.');
catch e
 tga_status(outputDirectory,'ERROR_RESUMABLE',total,sum([plan.Materialized]),e.message);rethrow(e);
end
end
function tga_status(d,status,requested,exported,message)
mil_json(fullfile(d,'STATUS.json'),struct('status',status,'requested_variants',requested,'materialized_csvs',exported,'message',message,'updated_at',datestr(now,30)));
fprintf('%s | %d/%d CSV files | %s\n',status,exported,requested,message);
end
function tga_index(d,plan,manifest,A)
writetable(struct2table(plan),fullfile(d,'VARIANT_MANIFEST.csv'));
rows=cell(numel(manifest),7);
for p=1:numel(manifest)
 item=manifest(p);ix=find(strcmp({plan.ParentKey},item.key),1);rows(p,:)={item.key,item.split,plan(ix).SuggestedAIRole,item.record_contains_fall,item.samples,plan(ix).StrictTrainOnlyGeneratorCalibration,strcmp(item.split,'test')};
end
T=cell2table(rows,'VariableNames',{'ParentKey','ReconstructionSplit','SuggestedAIRole','RecordContainsFall','Samples','StrictTrainOnlyGeneratorCalibration','HoldoutStressOnly'});writetable(T,fullfile(d,'AI_SPLIT_PROPOSAL.csv'));
mil_json(fullfile(d,'AI_PROTOCOL_STATUS.json'),struct('status','PROPOSAL_NOT_A_TRAINED_OR_VALIDATED_AI_MODEL','parent_grouping_required',true,'main_validation_test_must_use_real_measured',true,'test_parent_variants_are_stress_only',true,'generator_calibration_train_only_for_proposed_split',all([plan.StrictTrainOnlyGeneratorCalibration]),'warning','Original common calibration used seven BUILD files. A strict five-TRAIN/two-VAL protocol requires re-estimating generator calibration from TRAIN only before regenerating training variants. Do not label a post-hoc split as fully independent.','counts_per_parent',A.counts,'independent_parent_count',10));
end
