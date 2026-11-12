function C = ORIGINAL_CONFIG()
    % Nominal reconstruction only. Augmentation has its own configuration.
    C.project = 'MotorcycleIMULab';
    C.schema = 2;
    C.method = 'FULL_RECORD_CONDITIONAL_KINEMATIC_RECONSTRUCTION';
    % Sensor model and coordinate-frame priors.
    C.sensor.gravity_m_s2 = 9.81;
    C.sensor.nominal_position_body_m = [0.05 0 -0.05];
    C.sensor.mount_rpy_deg = [0 0 0]; % Sensor-to-body rotation: Rz(yaw)*Ry(pitch)*Rx(roll).
    C.sensor.acc_bias_prior_m_s2 = [0 0 0]; % A prior, not an identified calibration.
    % BUILD-only quiet-prefix calibration.
    C.calibration.scan_start_s = 0.5;
    C.calibration.scan_end_s = 5;
    C.calibration.segment_s = 0.5;
    C.calibration.max_gyro_std_deg_s = 0.6;
    C.calibration.max_gyro_mean_deg_s = 5;
    C.calibration.max_acc_std_m_s2 = 0.3;
    C.calibration.gravity_norm_tolerance_m_s2 = 1.5;
    C.calibration.minimum_build_files = 2;
    % Spline conditioning and numerical overlap.
    C.conditioning.degree = 5;
    C.conditioning.knot_spacing_s = 0.002;
    C.conditioning.block_duration_s = 2;
    C.conditioning.overlap_s = 0.25;
    C.conditioning.acc_difference_penalty = 1e-5;
    C.conditioning.gyro_difference_penalty = 1e-8;
    % Declared initial-state priors.
    C.initial.body_position_world_m = [0 0 1];
    C.initial.body_velocity_world_m_s = [0 0 0];
    C.initial.yaw_deg = 0;
    C.initial.tilt_prefix_s = [0.5 2];
    % Fixed full-record quality gates.
    C.quality.rmse_floor = [0.35 0.35 0.35 1 1 1];
    C.quality.rmse_range_fraction = 0.05;
    C.quality.minimum_correlation = 0.95;
    C.quality.correlation_std_floor = [0.1 0.1 0.1 0.5 0.5 0.5];
    C.quality.maximum_quaternion_norm_error = 1e-9;
    C.quality.maximum_forward_roundtrip_error = 1e-6;
    % Signal/state outputs and sharp report graphics.
    C.export.full_signal_csv = true;
    C.export.full_state_csv = true;
    C.export.figure_visible = false;
    C.export.maximum_plot_bins = 1200;
    C.export.png_dpi = 220;
    C.export.chart_font_size = 13;
    C.export.export_svg = true;
    C.export.make_result_zip = true;
end
