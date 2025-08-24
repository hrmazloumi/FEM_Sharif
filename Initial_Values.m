function params = Initial_Values(Raw_Mesh, Opt_Mesh)
%% INITIALIZATION
% Get number of nodes and elements from the optimized mesh
params.n_N = size(Opt_Mesh.Points, 1);      % Number of nodes
params.n_E = size(Opt_Mesh.ConnectivityList, 1);  % Number of elements

% Initialize area storage for each element
params.Area = zeros(params.n_E, 1);

%% THERMAL PROPERTIES
% Define material properties and boundary conditions for heat transfer analysis
params.h = 5;       % Convection coefficient [W/(m²·K)]
params.k = 10;      % Thermal conductivity [W/(m·K)]
params.T_inf = 100; % Ambient temperature [K]
params.Q = 2;       % Heat source magnitude [W/m²]

%% ELEMENT AREA CALCULATION
% Calculate area for each triangular element using the shoelace formula:
% Area = 0.5 * |x1y2 - x2y1 + x2y3 - x3y2 + x3y1 - x1y3|
%
% Note: Using the original linear mesh (Raw_Mesh) for area calculation
% since quadratic elements share the same base triangle geometry

% Preallocate coordinate arrays
X = zeros(1, 3);
Y = zeros(1, 3);

% Loop through all elements
for Element = 1:params.n_E
    % Extract coordinates of the three corner nodes for each element
    for i = 1:3
        node_id = Raw_Mesh.ConnectivityList(Element, i);
        X(i) = Raw_Mesh.Points(node_id, 1);  % X-coordinate
        Y(i) = Raw_Mesh.Points(node_id, 2);  % Y-coordinate
    end

    % Apply shoelace formula to calculate triangle area
    params.Area(Element) = 0.5 * abs(...
        X(1)*Y(2) - X(2)*Y(1) + ...
        X(2)*Y(3) - X(3)*Y(2) + ...
        X(3)*Y(1) - X(1)*Y(3));
end
end