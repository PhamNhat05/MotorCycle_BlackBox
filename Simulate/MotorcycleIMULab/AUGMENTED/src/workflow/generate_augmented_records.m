function runDirectory = generate_augmented_records(projectRoot, originalRun, runDirectory, config)
    % GENERATE_AUGMENTED_RECORDS Orchestrate 100 full-record variants per original source.
    % Inputs: root, completed original run, optional existing run and augmentation config.
    % Output: AUGMENTED/results directory. Original models are read without changes.

    % 1. Validate the original run and persist a deterministic, auditable recipe plan.
    context = validate_original_results(originalRun);
    manifest = context.manifest;
    plan = create_augmentation_plan(config, manifest);
    runDirectory = initialize_augmented_results(projectRoot, runDirectory, config, context, plan);
    write_json(fullfile(runDirectory, 'MATLAB_SELF_CHECKS.json'), augmentation_selfcheck());

    % 2. Reuse only completely exported variants with matching identities and hashes.
    plan = verify_completed_variants(runDirectory, plan, config);
    write_augmented_report(runDirectory, plan, manifest, config);
    [enoughSpace, requiredGB, availableGB] = check_augmentation_disk_space( ...
                                                                           runDirectory, plan, config);
    if ~enoughSpace
        write_augmentation_status(runDirectory, 'PENDING_DISK_SPACE', ...
                                  sum([plan.Materialized]), sprintf( ...
                                              'Need about %.2f GB free; available %.2f GB.', requiredGB, availableGB));
        return
    end

    fprintf('\nAUGMENTED | %d/1000 variants complete\nResults: %s\n', ...
            sum([plan.Materialized]), runDirectory);
    diary(fullfile(runDirectory, 'RUN_LOG.txt'));
    cleanup = onCleanup(@() diary('off'));
    try
        % 3. Load one parent at a time, then export each of its unfinished variants.
        for parentIndex = 1:numel(manifest)
            record = manifest(parentIndex);
            indices = find(strcmp({plan.ParentKey}, record.key));
            if all([plan(indices).Materialized])
                continue
            end
            saved = load(fullfile(originalRun, 'records', record.key, 'MODEL.mat'), 'M');
            model = saved.M;
            assert(numel(model.time_source_s) == record.samples ...
                   && size(model.measured_imu, 1) == record.samples);
            assert(isequaln(jsondecode(jsonencode(model.K)), context.frozen.K), ...
                   'Model calibration differs from the frozen original configuration.');
            sampled = query_imu(model, model.time_source_s);

            for recipeIndex = indices
                if plan(recipeIndex).Materialized
                    continue
                end
                if isfile(fullfile(runDirectory, 'STOP_AFTER_CURRENT_TASK.txt'))
                    write_augmentation_status(runDirectory, 'STOPPED_AT_VARIANT_BOUNDARY', ...
                                              sum([plan.Materialized]), 'Remove the stop file and call RUN_AUGMENT([], ''resume'').');
                    write_augmented_report(runDirectory, plan, manifest, config);
                    return
                end

                recipe = plan(recipeIndex);
                export_augmented_variant(runDirectory, model, sampled, record, ...
                                         recipe, config, context, parentIndex);
                plan(recipeIndex).Materialized = true;
                count = sum([plan.Materialized]);
                fprintf('%d/1000 | %s | %s | variant %03d | %d samples\n', ...
                        count, record.key, recipe.Group, recipe.VariantIndex, record.samples);
                if mod(count, config.progress_every) == 0
                    write_augmented_report(runDirectory, plan, manifest, config);
                    write_augmentation_status(runDirectory, 'RUNNING', count, ...
                                              'Exporting full CSVs and individual six-axis plots.');
                end
            end
        end

        % 4. Aggregate metrics only after every CSV/plot/parameter set is complete.
        write_augmented_report(runDirectory, plan, manifest, config);
        collect_variant_metrics(runDirectory, plan);
        assert(sum([plan.Materialized]) == 1000);
        write_augmentation_status(runDirectory, 'COMPLETE', 1000, ...
                                  '1000 CSVs and 1000 individual six-axis plots exported.');
    catch exception
        write_augmentation_status(runDirectory, 'ERROR_RESUMABLE', ...
                                  sum([plan.Materialized]), exception.message);
        try
            write_augmented_report(runDirectory, plan, manifest, config);
        catch
            % Preserve the export exception if updating the HTML index also fails.
        end
        rethrow(exception);
    end
end
