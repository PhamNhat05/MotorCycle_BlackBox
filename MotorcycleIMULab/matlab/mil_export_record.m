function mil_export_record(directory,A,M,C,T,D)
if ~isfolder(directory),mkdir(directory);end
save(fullfile(directory,'MODEL.partial.mat'),'M','-v7.3');movefile(fullfile(directory,'MODEL.partial.mat'),fullfile(directory,'MODEL.mat'),'f');
writetable(T,fullfile(directory,'AXIS_FIT.csv'));
Q=mil_query(M,A(:,1));
if C.export.full_signal_csv
 names={'Time_s','Real_Ax_m_s2','Real_Ay_m_s2','Real_Az_m_s2','Real_Gx_deg_s','Real_Gy_deg_s','Real_Gz_deg_s','Reconstructed_Ax_m_s2','Reconstructed_Ay_m_s2','Reconstructed_Az_m_s2','Reconstructed_Gx_deg_s','Reconstructed_Gy_deg_s','Reconstructed_Gz_deg_s'};
 mil_writecsv(fullfile(directory,'FULL_SIGNAL_COMPARISON.csv'),names,[A Q.imu]);
end
if C.export.full_state_csv
 names={'Time_s','BodyX_m','BodyY_m','BodyZ_m','BodyVx_m_s','BodyVy_m_s','BodyVz_m_s','BodyAx_m_s2','BodyAy_m_s2','BodyAz_m_s2','Qw','Qx','Qy','Qz','OmegaX_rad_s','OmegaY_rad_s','OmegaZ_rad_s','AlphaX_rad_s2','AlphaY_rad_s2','AlphaZ_rad_s2'};
 mil_writecsv(fullfile(directory,'FULL_STATE.csv'),names,[A(:,1) Q.body_position_world_m Q.body_velocity_world_m_s Q.body_acceleration_world_m_s2 Q.q Q.omega_body_rad_s Q.alpha_body_rad_s2]);
end
mil_plot(directory,A,Q.imu,T,C);
% QUALITY is the completion marker and is committed only after every export.
mil_json(fullfile(directory,'QUALITY.json'),D);
end
