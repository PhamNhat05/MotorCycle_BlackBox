function [Y, D] = condition_signals(t, X, C)
    % CONDITION_SIGNALS Fit overlapping degree-five splines to bias-corrected IMU channels.
    % Inputs: t: source seconds; X: N-by-6 corrected Acc/gyro; C: conditioning settings.
    % Outputs: Y: conditioned N-by-6 signals; D: full-record block coverage diagnostics.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Fixed wideband spline projection; overlap blending; no state resets [R4,R5].
    % Work in local seconds while retaining every original row.
    t = t(:) - t(1);
    dt = median(diff(t));
    N = numel(t);
    L = round(C.block_duration_s / dt) + 1;
    O = round(C.overlap_s / dt) + 1;
    hop = L - O;
    assert(hop > 0 && O >= 2 && C.knot_spacing_s >= dt);
    Y = zeros(size(X));
    W = zeros(N, 1);
    blocks = [];
    start = 1;
    count = 0;
    % Fit successive overlapping blocks; blend them before global integration.
    while true
        stop = min(N, start + L - 1);
        idx = start:stop;
        u = t(idx) - t(start);
        T = u(end);
        p = C.degree;
        assert(numel(idx) > p + 1);
        inside = C.knot_spacing_s:C.knot_spacing_s:T - 1e-10;
        knots = [zeros(1, p + 1) inside repmat(T, 1, p + 1)];
        B = build_spline_basis(u, knots, p);
        n = size(B, 2);
        % Penalize first coefficient differences for Acc and second differences for gyro.
        D1 = diff(speye(n), 1, 1);
        D2 = diff(speye(n), 2, 1);
        A1 = [B; sqrt(C.acc_difference_penalty) * D1];
        A2 = [B; sqrt(C.gyro_difference_penalty) * D2];
        Z = zeros(numel(idx), 6);
        Z(:, 1:3) = B * (A1 \ [X(idx, 1:3); zeros(size(D1, 1), 3)]);
        Z(:, 4:6) = B * (A2 \ [X(idx, 4:6); zeros(size(D2, 1), 3)]);
        % Cosine overlap weights avoid discontinuities at numerical block boundaries.
        weights = ones(numel(idx), 1);
        ramp = 0.5 - 0.5 * cos(linspace(0, pi, min(O, numel(idx)))');
        if start > 1
            weights(1:numel(ramp)) = ramp;
        end
        if stop < N
            weights(end - numel(ramp) + 1:end) = flipud(ramp);
        end
        Y(idx, :) = Y(idx, :) + weights .* Z;
        W(idx) = W(idx) + weights;
        count = count + 1;
        blocks(count, :) = [start stop]; %#ok<AGROW>
        if mod(count, 10) == 0 || stop == N
            fprintf('  Conditioning block %d | source %.3f / %.3f s\n', count, t(stop), t(end));
        end
        if stop == N
            break
        end
        start = start + hop;
    end
    % Every source sample must have positive coverage before normalization.
    assert(all(W > 0), 'An input sample was not covered.');
    Y = Y ./ W;
    D = struct('blocks', blocks, 'covered_samples', sum(W > 0), 'total_samples', N, 'minimum_weight', min(W), 'state_resets', 0, 'description', 'Overlapping numerical conditioning blocks; one subsequent full-record state integration.');
end
