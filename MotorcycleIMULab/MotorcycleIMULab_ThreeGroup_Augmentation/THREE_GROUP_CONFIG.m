function A=THREE_GROUP_CONFIG()
% Total default = 34 + 33 + 33 = 100 variants per parent, 1000 across ten.
A.schema=1;A.project='MotorcycleIMULab_ThreeGroup_Augmentation';
A.counts.bias_only=34;A.counts.position_only=33;A.counts.bias_and_position=33;
A.seed=20261101;
A.acc_bias_delta_bound_m_s2=[0.1 0.1 0.1];
A.gyro_bias_delta_bound_deg_s=[0.2 0.2 0.2];
A.position_delta_bound_body_m=[0.02 0.02 0.02];
A.export_mode='full_csv'; % 'compact' writes recipes without materializing CSVs.
A.chunk_rows=10000;A.disk_reserve_gb=2;A.estimated_csv_bytes_per_row=150;
% A proposal only: the old shared generator calibration used seven BUILD files.
% Re-estimate generator calibration on TRAIN only before claiming a strict 5:2:3 AI split.
A.ai_proposal.train={'fall_curve','fall_leaning','acceleration_straight','fall_like_1','fall_like_2'};
A.ai_proposal.validation={'fall_roundabout','harsh_braking_straight'};
A.ai_proposal.test={'fall_slippery_straight','acceleration_curve','fall_like_3'};
end
