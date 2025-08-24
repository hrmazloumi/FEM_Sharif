% =========================================================================
% Half-Bandwidth Calculation Function
% =========================================================================
function hbw = calculateHBW(meshStruct)
    % Calculates the half-bandwidth of the mesh's stiffness matrix.
    % The half-bandwidth is max(|i-j|) over all elements, where i and j are
    % nodes in the same element.
    
    elements = meshStruct.ConnectivityList;
    max_diff = 0;
    
    for i = 1:size(elements, 1)
        nodes_in_element = elements(i, :);
        % Find the difference between the max and min node ID in the element
        current_diff = max(nodes_in_element) - min(nodes_in_element);
        
        % Keep track of the maximum difference found so far
        if current_diff > max_diff
            max_diff = current_diff;
        end
    end
    
    hbw = max_diff;
end