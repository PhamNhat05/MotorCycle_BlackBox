function [enough, requiredGB, availableGB] = check_augmentation_disk_space(runDirectory, plan, config)
    % CHECK_AUGMENTATION_DISK_SPACE Estimate space needed for unfinished variants.
    % Outputs are a decision and decimal-GB estimates; this does not delete files.

    pending = find(~[plan.Materialized]);
    rowsNeeded = sum([plan(pending).Samples]);
    required = rowsNeeded * config.estimated_bytes_per_row ...
        + numel(pending) * (config.estimated_png_bytes_per_variant ...
                            + config.estimated_svg_bytes_per_variant + config.estimated_report_bytes_per_variant) ...
        + config.disk_reserve_gb * 1e9;
    disk = java.io.File(runDirectory);
    available = double(disk.getUsableSpace());
    requiredGB = required / 1e9;
    availableGB = available / 1e9;
    enough = isempty(pending) || available <= 0 || available >= required;
end
