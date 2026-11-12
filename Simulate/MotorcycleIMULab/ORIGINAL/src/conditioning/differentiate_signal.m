function d = differentiate_signal(x, h)
    % DIFFERENTIATE_SIGNAL Differentiate sampled signals with a five-point polynomial stencil.
    % Inputs: x: N-by-channels signal; h: sampling interval in seconds.
    % Outputs: d: derivative in input-units/second, including one-sided endpoint estimates.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Five-point local polynomial differentiation; endpoint weights derived [R6].
    N = size(x, 1);
    assert(N >= 5);
    d = zeros(size(x));
    % Interior: centered five-point polynomial derivative.
    d(3:N - 2, :) = (x(1:N - 4, :) - 8 * x(2:N - 3, :) + 8 * x(4:N - 1, :) - x(5:N, :)) / (12 * h);
    % Endpoints: solve one-sided polynomial moment constraints.
    for k = [1 2 N - 1 N]
        if k <= 2
            ids = 1:5;
        else
            ids = N - 4:N;
        end
        u = ids - k;
        V = u(:)'.^((0:4)');
        rhs = [0; 1; 0; 0; 0];
        a = V \ rhs;
        d(k, :) = (a' * x(ids, :)) / h;
    end
end
