function varargout = quaternion_math(action, varargin)
    % QUATERNION_MATH Provide scalar-first Hamilton quaternion and mounting operations.
    % Inputs: action selects multiply/conjugate/rotate/exp/rpy/tilt; varargin supplies operands.
    % Outputs: Quaternion, rotated vector or rotation matrix. Active attitude maps body to world.
    % Units and coordinate frames follow ORIGINAL/docs/MATHEMATICS.md.

    % Hamilton scalar-first quaternion algebra; active body-to-world rotation [R3].
    switch action
        case 'multiply'
            a = varargin{1};
            b = varargin{2};
            varargout{1} = [a(:, 1) .* b(:, 1) - sum(a(:, 2:4) .* b(:, 2:4), 2), a(:, 1) .* b(:, 2:4) + b(:, 1) .* a(:, 2:4) + cross(a(:, 2:4), b(:, 2:4), 2)];
        case 'conjugate'
            q = varargin{1};
            varargout{1} = [q(:, 1) -q(:, 2:4)];
        case 'rotate'
            q = varargin{1};
            v = varargin{2};
            u = q(:, 2:4);
            z = 2 * cross(u, v, 2);
            varargout{1} = v + q(:, 1) .* z + cross(u, z, 2);
        case 'exp'
            z = varargin{1};
            a = sqrt(sum(z.^2, 2));
            s = ones(size(a));
            j = a > 1e-12;
            s(j) = sin(a(j)) ./ a(j);
            varargout{1} = [cos(a) z .* s];
        case 'rpy'
            z = varargin{1} * pi / 180;
            r = z(1);
            p = z(2);
            y = z(3);
            Rx = [1 0 0; 0 cos(r) -sin(r); 0 sin(r) cos(r)];
            Ry = [cos(p) 0 sin(p); 0 1 0; -sin(p) 0 cos(p)];
            Rz = [cos(y) -sin(y) 0; sin(y) cos(y) 0; 0 0 1];
            varargout{1} = Rz * Ry * Rx;
        case 'tilt'
            f = varargin{1};
            yaw = varargin{2} * pi / 180;
            roll = atan2(f(2), f(3));
            pitch = atan2(-f(1), hypot(f(2), f(3)));
            qr = [cos(roll / 2) sin(roll / 2) 0 0];
            qp = [cos(pitch / 2) 0 sin(pitch / 2) 0];
            qy = [cos(yaw / 2) 0 0 sin(yaw / 2)];
            varargout{1} = quaternion_math('multiply', quaternion_math('multiply', qy, qp), qr);
        otherwise
            error('Unknown math operation: %s', action);
    end
end
