function B = build_spline_basis(t, knots, p)
    % BUILD_SPLINE_BASIS Evaluate a sparse clamped B-spline basis.
    % Inputs: t: sample times; knots: nondecreasing knot vector; p: polynomial degree.
    % Outputs: B: N-by-numberOfCoefficients sparse basis; at most p+1 nonzeros per row.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Local Cox-de Boor evaluation [R4,R5]; at most p+1 nonzero entries per row.
    t = t(:);
    knots = knots(:)';
    n = numel(knots) - p - 1;
    assert(all(t >= knots(1) - 1e-10 & t <= knots(end) + 1e-10));
    t = max(knots(1), min(t, knots(end)));
    breaks = unique(knots);
    bin = discretize(t, breaks);
    span = min(n, p + bin);
    N = zeros(numel(t), p + 1);
    N(:, 1) = 1;
    left = zeros(numel(t), p);
    right = left;
    for j = 1:p
        left(:, j) = t - knots(span + 1 - j)';
        right(:, j) = knots(span + j)' - t;
        saved = zeros(size(t));
        for r = 0:j - 1
            den = right(:, r + 1) + left(:, j - r);
            temp = N(:, r + 1) ./ den;
            N(:, r + 1) = saved + right(:, r + 1) .* temp;
            saved = left(:, j - r) .* temp;
        end
        N(:, j + 1) = saved;
    end
    cols = (span - p) + (0:p);
    rows = repmat((1:numel(t))', 1, p + 1);
    B = sparse(rows(:), cols(:), N(:), numel(t), n);
end
