function K_xy = Stiffness_Matrix(D_L, Raw_Mesh, Element)
%% INITIALIZATION
% Initialize Jacobian matrix and cell array for shape function derivatives
J = zeros(2);           % Jacobian matrix (2x2)
D_N_L = cell(1, 6);     % Cell array to store shape function derivatives in global coordinates

%% EXTRACT ELEMENT NODE COORDINATES
% Get coordinates of the three corner nodes for the specified element
X = zeros(1, 3);
Y = zeros(1, 3);
for i = 1:3
    node_id = Raw_Mesh.ConnectivityList(Element, i);
    X(i) = Raw_Mesh.Points(node_id, 1);  % X-coordinate
    Y(i) = Raw_Mesh.Points(node_id, 2);  % Y-coordinate
end

%% COMPUTE JACOBIAN MATRIX AND ITS INVERSE
% Jacobian matrix transforms from local (ξ,η) to global (x,y) coordinates
% J = [∂x/∂ξ  ∂y/∂ξ; ∂x/∂η  ∂y/∂η]
for i = 1:2
    J(i, 1) = X(i) - X(3);  % ∂x/∂ξ term
    J(i, 2) = Y(i) - Y(3);  % ∂y/∂ξ term
end
detJ = det(J);          % Determinant of Jacobian (area scaling factor)
J_inv = inv(J);         % Inverse of the Jacobian matrix

%% TRANSFORM SHAPE FUNCTION DERIVATIVES TO GLOBAL COORDINATES
% Transform derivatives from local (ξ,η) to global (x,y) coordinates using:
% ∇N_global = J⁻¹ * ∇N_local
for i = 1:6
    for j = 1:2
        for k = 1:4
            % Transform derivatives using inverse Jacobian
            D_N_L{i}(j, k) = J_inv(j, 1) * D_L{i}(1, k) + J_inv(j, 2) * D_L{i}(2, k);
        end
    end
end

%% INITIALIZE STIFFNESS MATRICES
% Initialize cell arrays for stiffness components
K_x = cell(6, 6);       % Cell array for x-component stiffness
K_y = cell(6, 6);       % Cell array for y-component stiffness
stiff_x = cell(6, 6);   % Temporary stiffness (x-component)
stiff_y = cell(6, 6);   % Temporary stiffness (y-component)
K_xy = zeros(6);        % Combined stiffness matrix (6x6)

%% ASSEMBLE STIFFNESS MATRICES
% Loop through all shape function pairs to compute stiffness contributions
for i = 1:6
    for j = 1:6
        %% COMPUTE STIFFNESS COMPONENTS
        % Compute outer products for x and y components
        stiff_x{i, j} = D_N_L{i}(1, :).' * D_N_L{j}(1, :);  % ∂N_i/∂x * ∂N_j/∂x
        stiff_y{i, j} = D_N_L{i}(2, :).' * D_N_L{j}(2, :);  % ∂N_i/∂y * ∂N_j/∂y
        
        %% APPLY NUMERICAL INTEGRATION WEIGHTS
        % For 3x3 submatrix (corner nodes) - using reduced integration weights
        for m = 1:3
            for n = 1:3
                if m == n
                    % Diagonal terms: weight = 1/6
                    K_x{i, j}(m, n) = stiff_x{i, j}(m, n) / 6;
                    K_y{i, j}(m, n) = stiff_y{i, j}(m, n) / 6;
                else
                    % Off-diagonal terms: weight = 1/12  
                    K_x{i, j}(m, n) = stiff_x{i, j}(m, n) / 12;
                    K_y{i, j}(m, n) = stiff_y{i, j}(m, n) / 12;
                end
            end
        end
        
        %% HANDLE MID-SIDE NODES (SPECIAL WEIGHTING)
        % Apply different weights for mid-side node interactions
        for m = 1:3
            % Weighted terms for corner-mid interactions: weight = 1/3
            K_x{i, j}(m, 4) = stiff_x{i, j}(m, 4) / 3;
            K_x{i, j}(4, m) = stiff_x{i, j}(m, 4) / 3;  % Symmetric
            K_y{i, j}(m, 4) = stiff_y{i, j}(m, 4) / 3;
            K_y{i, j}(4, m) = stiff_y{i, j}(m, 4) / 3;  % Symmetric
        end
        
        % Diagonal term for mid-side node: full weight (1.0)
        K_x{i, j}(4, 4) = stiff_x{i, j}(4, 4);
        K_y{i, j}(4, 4) = stiff_y{i, j}(4, 4);
        
        %% SUM CONTRIBUTIONS TO GLOBAL STIFFNESS MATRIX
        % Combine x and y components and sum all entries
        K_xy(i, j) = sum(sum(K_x{i, j})) + sum(sum(K_y{i, j}));
        
        %% APPLY JACOBIAN DETERMINANT (AREA SCALING)
        % Multiply by determinant to account for element area
        K_xy(i, j) = K_xy(i, j) * abs(detJ);
    end
end
end