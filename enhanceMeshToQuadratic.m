function Mesh = enhanceMeshToQuadratic(Raw_Mesh)

% --- Initialization ---
points = Raw_Mesh.Points;
elements = Raw_Mesh.ConnectivityList;

edgeMidpointMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
newNodeID = size(points, 1) + 1;

% Use a cell array to dynamically store new coordinates
newCoordsList = {};

% --- Find unique edges and calculate midpoint coordinates ---
for i = 1:size(elements, 1)
    nodes = elements(i, :);
    edges = [nodes(1), nodes(2);
        nodes(2), nodes(3);
        nodes(3), nodes(1)];

    for j = 1:3
        edge = edges(j, :);
        key = sprintf('%d_%d', min(edge), max(edge));

        if ~isKey(edgeMidpointMap, key)
            % Assign the new node ID
            edgeMidpointMap(key) = newNodeID;

            % Calculate midpoint coordinates
            coord1 = points(edge(1), :);
            coord2 = points(edge(2), :);
            midpointCoord = (coord1 + coord2) / 2;

            % Store the new coordinates
            newCoordsList{end+1} = midpointCoord;

            newNodeID = newNodeID + 1;
        end
    end
end

% --- Assemble the final points matrix for the 2nd-order mesh ---
% Convert cell array of new coordinates to a matrix
newCoordsMatrix = vertcat(newCoordsList{:});

% Combine old and new points
finalPoints = [points; newCoordsMatrix];

% Create the node number column
nodeNumbers = (1:size(finalPoints, 1))';

% Format the output struct b.Points
Mesh.Points = [finalPoints, nodeNumbers];

% --- Create the 6-node quadratic element connectivity ---
numElements = size(elements, 1);
quadraticElements = zeros(numElements, 6);

for i = 1:numElements
    p = elements(i, :); % Old points P1, P2, P3

    % Get the new midpoint node IDs from the map
    m12 = edgeMidpointMap(sprintf('%d_%d', min(p(1), p(2)), max(p(1), p(2))));
    m23 = edgeMidpointMap(sprintf('%d_%d', min(p(2), p(3)), max(p(2), p(3))));
    m31 = edgeMidpointMap(sprintf('%d_%d', min(p(3), p(1)), max(p(3), p(1))));

    % Create the new 6-node element
    quadraticElements(i, :) = [p(1), p(2), p(3), m12, m23, m31];
end

Mesh.ConnectivityList = quadraticElements;
Mesh.nodes_on_verts = Raw_Mesh.nodes_on_verts;
Mesh.nodes_on_edges = Raw_Mesh.nodes_on_edges;
end