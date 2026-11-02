function mil_report(runDirectory)
S=load(fullfile(runDirectory,'RUN_STATE.mat'),'manifest','C');items=S.manifest;
rows=cell(0,9);details={};body={};freeze='NOT FROZEN';if isfile(fullfile(runDirectory,'FROZEN_CONFIGURATION.json')),freeze='FROZEN BEFORE TEST';end
for k=1:numel(items)
 item=items(k);d=fullfile(runDirectory,'records',item.key);qf=fullfile(d,'QUALITY.json');state='PENDING';
 if isfile(qf)
  D=jsondecode(fileread(qf));T=readtable(fullfile(d,'AXIS_FIT.csv'),'TextType','string');
  if D.pass,state='PASS';else,state='FAIL';end
  TT=addvars(T,repmat(string(item.key),height(T),1),repmat(string(item.split),height(T),1),'Before',1,'NewVariableNames',{'Record','Split'});details{end+1}=TT; %#ok<AGROW>
  rows(end+1,:)={item.key,item.split,state,D.scored_samples,item.first_time_s,item.last_time_s,D.leading_all_zero_samples,D.end_body_displacement_m,D.maximum_body_speed_m_s}; %#ok<AGROW>
  b=sprintf('<h2>%s (%s): %s</h2><p>Full record: %.3f to %.3f s; %d scored samples per axis; 0 excluded. Leading all-zero rows: %d, retained.</p>',item.key,upper(item.split),state,item.first_time_s,item.last_time_s,D.scored_samples,D.leading_all_zero_samples);
  b=[b '<table><tr><th>Axis</th><th>RMSE</th><th>MAE</th><th>Max error</th><th>r</th><th>NRMSE fit %</th><th>RMSE limit</th><th>Pass</th></tr>'];
  for j=1:6,b=[b sprintf('<tr><td>%s</td><td>%.5g</td><td>%.5g</td><td>%.5g</td><td>%.5f</td><td>%.2f</td><td>%.5g</td><td>%s</td></tr>',char(T.Axis(j)),T.RMSE(j),T.MAE(j),T.MaxAbsError(j),T.PearsonR(j),T.NRMSEFit_percent(j),T.RMSELimit(j),string(T.Pass(j)))];end %#ok<AGROW>
  b=[b '</table>' sprintf('<p>Numerical checks: quaternion norm error %.3g; forward roundtrip maximum error %.3g; finite state %s.</p>',D.quaternion_norm_max_error,D.forward_roundtrip_max_abs,string(D.finite_state)) sprintf('<p>Unvalidated integrated displacement: %.2f m; maximum speed: %.2f m/s. These are drift diagnostics, not measured trajectory errors.</p>',D.end_body_displacement_m,D.maximum_body_speed_m_s)];
  b=[b sprintf('<p><a href="records/%s/FULL_SIGNAL_COMPARISON.csv">Full signal CSV</a> | <a href="records/%s/FULL_STATE.csv">Full state CSV</a> | <a href="records/%s/AXIS_FIT.csv">Axis fit CSV</a></p><img src="records/%s/FULL_RECORD_FIT.png" alt="Full record fit">',item.key,item.key,item.key,item.key)];
  vf=fullfile(d,'VIDEO_STATUS.json');if isfile(vf),V=jsondecode(fileread(vf));if strcmp(V.status,'COMPLETE'),b=[b sprintf('<p><a href="records/%s/%s">Full-record simulation video</a></p>',item.key,V.filename)];else,b=[b '<p>Video export failed; use EXPORT_VIDEOS.</p>'];end,end
  body{end+1}=b; %#ok<AGROW>
 else
  rows(end+1,:)={item.key,item.split,state,0,item.first_time_s,item.last_time_s,item.leading_all_zero_samples,NaN,NaN}; %#ok<AGROW>
 end
end
summary=cell2table(rows,'VariableNames',{'Record','Split','Status','ScoredSamples','FirstSourceTime_s','LastSourceTime_s','LeadingZeroRows','IntegratedDisplacement_m','MaxIntegratedSpeed_m_s'});
writetable(summary,fullfile(runDirectory,'RECORD_SUMMARY.csv'));
if ~isempty(details),allAxis=vertcat(details{:});writetable(allAxis,fullfile(runDirectory,'ALL_AXIS_FIT.csv'));end
status='IN PROGRESS';f=fullfile(runDirectory,'STATUS.json');if isfile(f),V=jsondecode(fileread(f));status=V.status;end
aug='NOT STARTED';f=fullfile(runDirectory,'augmentation','STATUS.json');if isfile(f),V=jsondecode(fileread(f));aug=V.status;end
html=['<!doctype html><html lang="en"><meta charset="utf-8"><title>MotorcycleIMULab report</title><style>body{font:16px system-ui;max-width:1250px;margin:35px auto;padding:0 24px;color:#182531}h1,h2{color:#153b55}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:8px;border:1px solid #d0d9df;text-align:right}th:first-child,td:first-child{text-align:left}th{background:#edf3f7}img{width:100%;height:auto}.scope{padding:16px;background:#fff4db;line-height:1.6}</style><body><h1>MotorcycleIMULab: full-record report</h1>'];
html=[html sprintf('<p>Workflow: <b>%s</b><br>Common configuration: <b>%s</b><br>Augmentation: <b>%s</b></p>',status,freeze,aug)];
html=[html '<div class="scope">Scope: IMU-conditioned kinematic reconstruction, tested with a fixed shared configuration on three held-out recordings. Each TEST trajectory still uses that recording''s six IMU channels. The fit is an in-sample forward roundtrip, not a blind forecast or an independent validation of the 3D trajectory. No GPS, optical ground truth, road contact or independent rider motion is available. A high fit percentage must not be presented as trajectory accuracy.</div>'];
configText='';candidate=fullfile(runDirectory,'CANDIDATE_CONFIGURATION.mat');
if isfile(candidate)
 Kdata=load(candidate,'K');K=Kdata.K;
 configText=sprintf('<h2>Common configuration</h2><p>Bias [Ax Ay Az] = [%.6g %.6g %.6g] m/s^2; [Gx Gy Gz] = [%.6g %.6g %.6g] deg/s.<br>Nominal sensor position in body = [%.4g %.4g %.4g] m. Mount RPY = [%.4g %.4g %.4g] deg.<br>Gyro quiet-prefix prior uses BUILD only. Accelerometer bias, mounting and lever arm are fixed assumptions, not identified parameters.</p>',K.bias,K.nominal_position_body_m,S.C.sensor.mount_rpy_deg);
 if isfile(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256')),configText=[configText '<p>Frozen SHA-256: <code>' strtrim(fileread(fullfile(runDirectory,'FROZEN_CONFIGURATION.sha256'))) '</code></p>'];end
end
html=[html configText '<p>Data edition: the supplied CSVs have not been matched to the publisher correction of Ay. A good IMU fit does not resolve that issue. <a href="documentation/DATA_PROVENANCE.md">Data provenance</a> | <a href="documentation/REFERENCES.md">Primary references</a> | <a href="documentation/MATHEMATICS.md">Equations</a></p>'];
html=[html '<p>All samples in each processed file are scored, including startup zeros and pre/post-event motion. Plotting uses a min/max envelope only. NRMSE fit = 100(1 - ||measured-reconstructed|| / ||measured-mean(measured)||); it may be negative and is undefined for constant channels. See ALL_AXIS_FIT.csv for every axis.</p>'];
html=[html '<p>Fixed gate: RMSE &le; max(axis floor, 5% of full-record range); r &ge; 0.95 when real standard deviation exceeds the declared floor; finite states and unit-quaternion/forward-model checks. Floors: 0.35 m/s^2 for acceleration, 1 deg/s for gyro. These are project acceptance choices.</p>'];
html=[html '<table><tr><th>Record</th><th>Split</th><th>Status</th><th>Scored samples/axis</th><th>First s</th><th>Last s</th></tr>'];
for k=1:height(summary),html=[html sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%.3f</td><td>%.3f</td></tr>',summary.Record{k},upper(summary.Split{k}),summary.Status{k},summary.ScoredSamples(k),summary.FirstSourceTime_s(k),summary.LastSourceTime_s(k))];end %#ok<AGROW>
html=[html '</table>' strjoin(body,newline) '<p>Bulk augmented CSV files remain in augmentation/ and are excluded from the upload report ZIP. They can occupy many gigabytes. Recipe files, manifests and completion checks are included.</p></body></html>'];
fid=fopen(fullfile(runDirectory,'REPORT.html'),'w','n','UTF-8');fwrite(fid,html,'char');fclose(fid);
md=sprintf('# MotorcycleIMULab result\n\nWorkflow: %s\n\nConfiguration: %s\n\nAugmentation: %s\n\nOpen REPORT.html for six-axis full-record fits and videos. ALL_AXIS_FIT.csv contains numerical results. High IMU fit is not independent 3D validation. TEST uses each held-out record as reconstruction input.\n',status,freeze,aug);
fid=fopen(fullfile(runDirectory,'REPORT.md'),'w');fwrite(fid,md,'char');fclose(fid);
end
