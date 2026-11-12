function A = AUGMENTATION_CONFIG()
    % New experimental augmentation bounds, independent of the ORIGINAL settings.
    A.schema = 2;
    A.seed = 20261109;
    % Exactly 100 variants per parent: 34 + 33 + 33.
    A.counts.bias_only = 34;
    A.counts.position_only = 33;
    A.counts.bias_and_position = 33;
    % Constant electronic offsets: acceleration in m/s^2, gyro in deg/s.
    A.acc_bias_delta_bound_m_s2 = [10 10 10];
    A.gyro_bias_delta_bound_deg_s = [0.2 0.2 0.2];
    % The displacement bound applies to the vector norm, not each coordinate.
    A.position_delta_max_norm_m = 0.5; % norm(dr), not a 0.5 m bound on each coordinate.
    % Readable charts: vector SVG for HTML and high-resolution PNG for download.
    A.plot_bins = 1000;
    A.png_dpi = 220;
    A.zoom_half_width_s = 0.65;
    A.chart_font_size = 13;
    A.export_svg = true;
    A.progress_every = 10;
    A.resume_verify_hashes = true;
    A.disk_reserve_gb = 2;
    A.estimated_bytes_per_row = 110;
    A.estimated_png_bytes_per_variant = 4e6;
    A.estimated_svg_bytes_per_variant = 4e6;
    A.estimated_report_bytes_per_variant = 40000;
    A.scope = 'SAME_LATENT_MOTION_CONSTANT_BIAS_AND_FIXED_BODY_POSITION';
end
