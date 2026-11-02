function K=mil_calibrate(root,C,manifest)
% Gyro prior from seven BUILD quiet prefixes only; stationarity is conditional.
ids=find(strcmp({manifest.split},'build'));assert(numel(ids)==7);
means=[];records=cell(7,1);
for j=1:7
 item=manifest(ids(j));A=mil_read(root,item);candidates=[];windows=[];
 for s=C.calibration.scan_start_s:C.calibration.segment_s:C.calibration.scan_end_s-C.calibration.segment_s
  Q=A(A(:,1)>=s & A(:,1)<s+C.calibration.segment_s,:);a=Q(:,2:4);g=Q(:,5:7);
  if size(Q,1)<round(0.99*C.calibration.segment_s*1000),continue;end
  good=max(std(g,0,1))<=C.calibration.max_gyro_std_deg_s && max(abs(mean(g,1)))<=C.calibration.max_gyro_mean_deg_s && max(std(a,0,1))<=C.calibration.max_acc_std_m_s2 && abs(norm(mean(a,1))-C.sensor.gravity_m_s2)<=C.calibration.gravity_norm_tolerance_m_s2;
  if good,candidates(end+1,:)=mean(g,1);windows(end+1,:)=[s s+C.calibration.segment_s];end %#ok<AGROW>
 end
 if ~isempty(candidates),means(end+1,:)=median(candidates,1);end %#ok<AGROW>
 records{j}=struct('key',item.key,'quiet_windows_source_s',windows,'gyro_means_deg_s',candidates);
end
assert(size(means,1)>=C.calibration.minimum_build_files,'Insufficient quiet BUILD files. Inspect calibration; TEST was not used.');
K.bias=[C.sensor.acc_bias_prior_m_s2 median(means,1)];
K.sensor_to_body=mil_math('rpy',C.sensor.mount_rpy_deg);
K.nominal_position_body_m=C.sensor.nominal_position_body_m;
K.gravity_world_m_s2=[0 0 -C.sensor.gravity_m_s2];
K.build_keys={manifest(ids).key};K.test_values_used=false;K.acc_bias_identified=false;
K.mount_and_lever_identified=false;K.stationarity_independently_verified=false;
K.calibration_records=records;K.build_files_with_quiet_prefix=size(means,1);
K.method='BUILD_ONLY_MEDIAN_QUIET_PREFIX_WITH_FIXED_ACCELEROMETER_PRIOR';
end
