function mil_augment(runDirectory,C)
% Fixed body-frame lever translation + constant six-axis bias [R3,R7].
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'manifest');manifest=S.manifest;
R=mil_collect(runDirectory,manifest,'all');assert(numel(R)==10 && all([R.pass]),'All seven BUILD and three TEST gates must pass before augmentation.');
lock=fullfile(runDirectory,'FROZEN_CONFIGURATION.json');assert(isfile(lock),'No frozen configuration.');
frozenHash=mil_hash(lock);assert(strcmp(frozenHash,strtrim(fileread(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256')))),'Frozen configuration changed.');
assert(ismember(C.augmentation.export_mode,{'full_csv','compact'}),'Choose full_csv or compact.');
parentIds=find(strcmp({manifest.split},'build'));out=fullfile(runDirectory,'augmentation');if ~isfolder(out),mkdir(out);end
bound=[C.augmentation.acc_bias_delta_bound_m_s2 C.augmentation.gyro_bias_delta_bound_deg_s C.augmentation.position_delta_bound_body_m];
plan=[];nplan=0;neededRows=0;
for p=1:7
 item=manifest(parentIds(p));parentFile=fullfile(runDirectory,'records',item.key,'MODEL.mat');parentHash=mil_hash(parentFile);
 SS=load(parentFile,'M');M=SS.M;d=fullfile(out,item.key);if ~isfolder(d),mkdir(d);end
 stream=RandStream('mt19937ar','Seed',C.augmentation.seed+p);deltas=(2*rand(stream,C.augmentation.samples_per_build_file,9)-1).*bound;
 for v=1:C.augmentation.samples_per_build_file
  db=deltas(v,1:6);dr=deltas(v,7:9);D=struct('schema',1,'parent_key',item.key,'parent_split','build','variant_index',v,'parent_input_sha256',item.sha256,'parent_model_sha256',parentHash,'frozen_configuration_sha256',frozenHash,'bias_delta',db,'bias',M.K.bias+db,'position_delta_body_m',dr,'position_body_m',M.K.nominal_position_body_m+dr,'record_contains_fall',item.record_contains_fall,'reference_contact_start_s',item.reference_contact_start_s,'reference_contact_end_s',item.reference_contact_end_s,'source_first_s',item.first_time_s,'source_last_s',item.last_time_s,'samples',item.samples,'scope','SENSOR_PERTURBATION_SAME_LATENT_MOTION_NOT_NEW_PHYSICAL_FALL','timing_preserved',true,'publisher_corrected_edition_verified',false,'augmentation_bounds_status','PROJECT_ASSUMPTIONS_NOT_HARDWARE_CERTIFICATION');
  def=fullfile(d,sprintf('variant_%04d.json',v));
  if isfile(def),assert(isequaln(jsondecode(fileread(def)),jsondecode(jsonencode(D))),'Existing variant definition changed.');else,mil_json(def,D);end
  csvFile=fullfile(d,sprintf('variant_%04d.csv',v));done=isfile(csvFile) && isfile([csvFile '.complete.json']);
  if ~done,neededRows=neededRows+item.samples;end
  nplan=nplan+1;entry=struct('ParentKey',item.key,'VariantIndex',v,'Samples',item.samples,'DeltaAx',db(1),'DeltaAy',db(2),'DeltaAz',db(3),'DeltaGx',db(4),'DeltaGy',db(5),'DeltaGz',db(6),'DeltaX_m',dr(1),'DeltaY_m',dr(2),'DeltaZ_m',dr(3),'Materialized',done);
  if isempty(plan),plan=entry;else,plan(nplan)=entry;end
 end
end
writetable(struct2table(plan),fullfile(out,'VARIANT_MANIFEST.csv'));
if strcmp(C.augmentation.export_mode,'compact')
 mil_json(fullfile(out,'STATUS.json'),struct('status','COMPACT_RECIPES_COMPLETE','definitions',nplan,'all_csv_materialized',all([plan.Materialized]),'message','Exact definitions saved. Use LOAD_VARIANT, or EXPORT_AUGMENTED_DATA(runDirectory,full_csv) to materialize.'));
 return;
end
requiredBytes=neededRows*C.augmentation.estimated_csv_bytes_per_row+C.augmentation.disk_reserve_gb*1e9;
disk=java.io.File(runDirectory);freeBytes=double(disk.getUsableSpace());
if freeBytes>0 && freeBytes<requiredBytes
 mil_json(fullfile(out,'STATUS.json'),struct('status','PENDING_DISK_SPACE','definitions',nplan,'estimated_required_free_gb',requiredBytes/1e9,'available_free_gb',freeBytes/1e9,'message','Free space, then EXPORT_AUGMENTED_DATA. Full CSV export has not been declared complete.'));
 fprintf('Augmentation recipes saved. Full CSV export needs approximately %.1f GB free; available %.1f GB.\n',requiredBytes/1e9,freeBytes/1e9);return;
end
names={'Time_s','Ax_m_s2','Ay_m_s2','Az_m_s2','Gx_deg_s','Gy_deg_s','Gz_deg_s'};
for p=1:7
 item=manifest(parentIds(p));SS=load(fullfile(runDirectory,'records',item.key,'MODEL.mat'),'M');M=SS.M;Q=mil_query(M,M.time_source_s);N=numel(M.time_source_s);d=fullfile(out,item.key);
 for v=1:C.augmentation.samples_per_build_file
  if isfile(fullfile(runDirectory,'STOP_AFTER_CURRENT_TASK.txt'))
   mil_json(fullfile(out,'STATUS.json'),struct('status','STOPPED_AT_VARIANT_BOUNDARY','message','Remove STOP_AFTER_CURRENT_TASK.txt, then EXPORT_AUGMENTED_DATA.'));return;
  end
  file=fullfile(d,sprintf('variant_%04d.csv',v));if isfile(file) && isfile([file '.complete.json']),continue;end
  D=jsondecode(fileread(fullfile(d,sprintf('variant_%04d.json',v))));dr=reshape(D.position_delta_body_m,1,3);db=reshape(D.bias_delta,1,6);
  tmp=[file '.partial'];fid=fopen(tmp,'w');assert(fid>=0);fprintf(fid,'%s\n',strjoin(names,','));maxConsistency=0;finite=true;maxAbs=zeros(1,6);maxDelta=zeros(1,6);
  try
   for a=1:C.augmentation.chunk_rows:N
    ids=a:min(N,a+C.augmentation.chunk_rows-1);deltaR=repmat(dr,numel(ids),1);w=Q.omega_body_rad_s(ids,:);alpha=Q.alpha_body_rad_s2(ids,:);
    deltaF=(cross(alpha,deltaR,2)+cross(w,cross(w,deltaR,2),2))*M.K.sensor_to_body;
    Y=Q.imu(ids,:)+[deltaF zeros(numel(ids),3)]+db;
    maxAbs=max(maxAbs,max(abs(Y),[],1));maxDelta=max(maxDelta,max(abs(Y-Q.imu(ids,:)),[],1));
    checkIds=unique(round(linspace(1,numel(ids),min(3,numel(ids)))));exact=mil_query(M,M.time_source_s(ids(checkIds)),D.position_body_m,D.bias);
    maxConsistency=max(maxConsistency,max(abs(exact.imu-Y(checkIds,:)),[],'all'));finite=finite && all(isfinite(Y(:)));
    assert(finite && maxConsistency<1e-6,'Variant forward-model consistency failed.');
    fprintf(fid,'%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g\n',[M.time_source_s(ids) Y]');
   end
   fclose(fid);
  catch e,fclose(fid);rethrow(e);end
  movefile(tmp,file,'f');mil_json([file '.complete.json'],struct('samples',N,'sha256',mil_hash(file),'finite',finite,'forward_consistency_max_abs',maxConsistency,'parent_model_sha256',D.parent_model_sha256,'axis_max_abs',maxAbs,'axis_max_change_from_nominal',maxDelta,'hardware_range_verified',false));
  plan((p-1)*C.augmentation.samples_per_build_file+v).Materialized=true;
  writetable(struct2table(plan),fullfile(out,'VARIANT_MANIFEST.csv'));
  fprintf('  Augmented full record %s %d/%d | %d rows\n',item.key,v,C.augmentation.samples_per_build_file,N);
 end
 clear M Q;
end
mil_json(fullfile(out,'STATUS.json'),struct('status','FULL_CSV_EXPORT_COMPLETE','definitions',nplan,'csv_files',sum([plan.Materialized]),'all_csv_materialized',all([plan.Materialized]),'excluded_from_result_zip',true));
end
