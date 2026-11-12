function checks = CHECK_PROJECT()
    % CHECK_PROJECT Validate numerical kernels and augmentation rules on synthetic data.
    % This check does not reconstruct the ten real files or export a dataset.

    SETUP_PROJECT();
    checks = struct('original', original_selfcheck(), ...
                    'augmented', augmentation_selfcheck());
    fprintf('ORIGINAL numerical checks: PASS\n');
    fprintf('AUGMENTED recipe and formula checks: PASS\n');
end
