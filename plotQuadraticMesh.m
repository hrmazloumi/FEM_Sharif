% =========================================================================
% Plotting Function
% =========================================================================
function plotQuadraticMesh(meshstruct)
    % Plots a 2nd-order (6-node) triangular mesh with node labels and filled elements.
    %
    % Args:
    %     meshStruct (struct): A struct with fields:
    %       - Points: [m_nodes x 3] matrix of [X, Y, Node_ID].
    %       - ConnectivityList: [n_elements x 6] matrix for quadratic triangles.

    points = meshstruct.Points;
    elements = meshstruct.ConnectivityList;

    % --- Plot the mesh elements with color fill ---
    % Use the patch command to draw filled triangles based on the corner nodes.
    patch('Faces', elements(:, 1:3), ...
          'Vertices', points(:, 1:2), ...
          'FaceColor', [0.7 0.85 1.0], ... % A light blue color
          'EdgeColor', 'b', ...
          'LineWidth', 1.5);
    
    hold on; % Keep the plot active to add nodes and labels

    % --- Plot all nodes (corners and midpoints) ---
    % Plot all nodes as black dots
    plot(points(:, 1), points(:, 2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);

    % --- Add text labels for each node number ---
    % Add a small offset to the text so it doesn't sit directly on the node
    textOffset = (max(points(:,1)) - min(points(:,1))) * 0.015; 
    
    for i = 1:size(points, 1)
        x = points(i, 1);
        y = points(i, 2);
        nodeID = points(i, 3);
        
        text(x + textOffset, y + textOffset, num2str(nodeID), ...
             'FontSize', 9, ...
             'Color', [0.8500 0.3250 0.0980], ... % Orange color for visibility
             'FontWeight', 'bold');
    end
    
    % --- Final plot adjustments ---
    hold off;
    axis equal;
    grid on;
    title('2nd-Order Mesh with Node Labels');
    xlabel('X-coordinate');
    ylabel('Y-coordinate');
    set(gca, 'FontSize', 12); % Set axis font size
end