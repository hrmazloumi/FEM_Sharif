function [K, F] = AssembleyMatrix(D_L,params, Raw_Mesh, Opt_Mesh)
%% MATRIX PREALLOCATION
% Preallocate global stiffness matrix and force vector
K = zeros(params.n_N);      % Global stiffness matrix
F = zeros(params.n_N, 1);   % Global force vector

%% ELEMENT CONNECTIVITY REORDERING
% Reorder element connectivity list for proper node ordering
% (This appears to be mapping from one ordering convention to another)
Elemntslist = zeros(params.n_E, 6);
Elemntslist(:, 1) = Opt_Mesh.ConnectivityList(:, 1);
Elemntslist(:, 2) = Opt_Mesh.ConnectivityList(:, 3);
Elemntslist(:, 3) = Opt_Mesh.ConnectivityList(:, 2);
Elemntslist(:, 4) = Opt_Mesh.ConnectivityList(:, 5);
Elemntslist(:, 5) = Opt_Mesh.ConnectivityList(:, 4);
Elemntslist(:, 6) = Opt_Mesh.ConnectivityList(:, 6);

%% ELEMENT-BY-ELEMENT ASSEMBLY
% Loop through all elements to assemble global matrices
for i = 1:params.n_E
    %% ELEMENT STIFFNESS MATRIX COMPUTATION
    % Compute element stiffness matrix and area
    K_xy = params.Area(i) * params.k * Stiffness_Matrix(D_L, Raw_Mesh, i);
    
    %% ELEMENT FORCE VECTOR COMPUTATION
    % Compute element force vector (distributed load)
    % Q * area / 3 distributed equally to the three corner nodes
    Q = (params.Q * params.Area(i) / 3) * [0; 0; 0; 1; 1; 1];
    
    %% GLOBAL MATRIX ASSEMBLY
    % Assemble element contributions into global matrices
    for j = 1:6  % Loop through element nodes (rows)
        % Add to global force vector
        F(Elemntslist(i, j)) = F(Elemntslist(i, j)) + Q(j, 1);
        for k = 1:6  % Loop through element nodes (columns)
            % Add to global stiffness matrix
            K(Elemntslist(i, j), Elemntslist(i, k)) = K(Elemntslist(i, j), Elemntslist(i, k)) + K_xy(j, k);
        end
    end
end
end