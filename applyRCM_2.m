function Mesh = applyRCM_2(meshstruct)
% Applies the Reverse Cuthill-McKee algorithm to reorder the nodes
% of a 2nd-order mesh to reduce matrix bandwidth.

points = meshstruct.Points;
elements = meshstruct.ConnectivityList;
numNodes = size(points, 1);

% --- 1. Build Adjacency Matrix ---
% An adjacency matrix A has A(i,j) = 1 if node i and j are connected.
adj = sparse(numNodes, numNodes);

% For each 6-node element, all nodes are connected to each other.
for i = 1:size(elements, 1)
    nodes = elements(i, :);
    % Create all pairs of nodes within the element
    [p, q] = meshgrid(nodes, nodes);
    pairs = unique([p(:), q(:)], 'rows');
    % Remove self-connections
    pairs = pairs(pairs(:,1) ~= pairs(:,2), :);
    % Create linear indices for sparse matrix assignment
    indices = sub2ind(size(adj), pairs(:,1), pairs(:,2));
    adj(indices) = 1;
end

% --- 2. Run MATLAB's symrcm function ---
% This function computes the reverse Cuthill-McKee ordering.
p_rcm = symrcm(adj);

% --- 3. Apply the new ordering (permutation) ---
% The permutation vector p_rcm tells us where each old node should go.
% We need an inverse mapping to apply it easily.
inv_p(p_rcm) = 1:numNodes;

% Reorder the points matrix
Mesh.Points = zeros(size(points));
for i = 1:numNodes
    new_node_id = inv_p(i);
    Mesh.Points(new_node_id, 1:2) = points(i, 1:2);
    Mesh.Points(new_node_id, 3) = new_node_id; % Update the node ID column
end

% Reorder the connectivity list
Mesh.ConnectivityList = inv_p(elements);

% --- 4. Reorder nodes_on_edges and nodes_on_verts matrices ---
% Update node numbers in boundary matrices using the inverse permutation
if isfield(meshstruct, 'nodes_on_edges') && ~isempty(meshstruct.nodes_on_edges)
    nodes_on_edges = meshstruct.nodes_on_edges;
    % Update node numbers (3rd column) using the inverse permutation
    nodes_on_edges(:, 3) = inv_p(nodes_on_edges(:, 3));
    Mesh.nodes_on_edges = nodes_on_edges;
end

if isfield(meshstruct, 'nodes_on_verts') && ~isempty(meshstruct.nodes_on_verts)
    nodes_on_verts = meshstruct.nodes_on_verts;
    % Update node numbers (3rd column) using the inverse permutation
    nodes_on_verts(:, 3) = inv_p(nodes_on_verts(:, 3));
    Mesh.nodes_on_verts = nodes_on_verts;
end

% Copy any other fields that might exist in the meshstruct
other_fields = setdiff(fieldnames(meshstruct), {'Points', 'ConnectivityList', 'nodes_on_edges', 'nodes_on_verts'});
for i = 1:length(other_fields)
    field_name = other_fields{i};
    Mesh.(field_name) = meshstruct.(field_name);
end
end