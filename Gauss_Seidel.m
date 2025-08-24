function T = Gauss_Seidel(params, Q, q, K, H)
% GAUSS_SEIDEL Solves the thermal system using Gauss-Seidel iteration
%
% Inputs:
%   params  - Structure containing material properties:
%             * k: Thermal conductivity [W/m-K]
%             * Area: Cross-sectional area [m^2]
%             * h: Convection coefficient [W/m^2-K]
%   Q       - 6x1 heat source vector [W]
%   q       - 6x3 heat flux matrix [W]
%   K       - 6x6 stiffness matrix [W/K]
%   H       - 6x6 convection matrix [W/K]
%
% Output:
%   T_exact - 6x1 exact solution vector [K] (for verification)

%% Assemble System Matrices
% Combine conduction and convection terms
K = params.k * params.Area * K + params.h * (10^0.5) * H;

% Assemble force vector (using second column of q matrix)
f = Q + q(:, 2);

%% Gauss-Seidel Iteration Setup
T = zeros(6, 1);        % Initial guess (0K everywhere)
max_iter = 100;         % Maximum allowed iterations
tol = 1e-6;             % Convergence tolerance
converged = false;      % Convergence flag

%% Iterative Solution
for k = 1:max_iter
    T_old = T;          % Store previous solution

    % Update each degree of freedom sequentially
    for i = 1:6
        % Compute sum of K(i,j)*T(j) for j≠i
        sigma = K(i,:) * T - K(i,i) * T(i);

        % Gauss-Seidel update formula
        T(i) = (f(i) - sigma) / K(i,i);
    end

    % Check convergence
    error = norm(T - T_old);
    if error < tol
        converged = true;
        break;
    end
end

%% Display Results
if converged
    fprintf('\nConverged in %d iterations (Error = %.2e).\n\n', k, error);
else
    warning('Did not converge in %d iterations (Final error = %.2e)', ...
        max_iter, error);
end
end