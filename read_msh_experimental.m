function mesh = read_msh_experimental(filename)
% READ_MSH Parses a Gmsh .msh file (version 4.1) and extracts node 
% coordinates and element connectivity for 3-node triangles.
%
%   MESH = READ_MSH(FILENAME) reads the specified .msh file and returns a 
%   structure MESH with two fields:
%
%   - MESH.Points: An (N x 2) matrix where N is the number of nodes. Each 
%     row contains the [X, Y] coordinates for a node.
%   - MESH.ConnectivityList: An (M x 3) matrix where M is the number of 
%     3-node triangular elements. Each row contains the three node tags 
%     that define a triangle.
%
%   This function is specifically tailored for the MSH v4.1 format where
%   node tags and their coordinates are listed in separate blocks. It will
%   correctly filter for and extract only 3-node triangles (elementType 2).

    % --- 1. File Validation and Setup ---
    if ~exist(filename, 'file')
        error('File not found: %s', filename);
    end

    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file for reading: %s', filename);
    end

    % Initialize the output structure
    mesh = struct('Points', [], 'ConnectivityList', []);
    
    % --- 2. Read File Line-by-Line to Find Sections ---
    current_line = fgetl(fid);
    while ischar(current_line)
        
        % --- 3. Parse the $Nodes Section ---
        if strcmp(current_line, '$Nodes')
            % The first line after the header contains overall node information
            % Format: numEntityBlocks numNodes minNodeTag maxNodeTag
            header_line = str2num(fgetl(fid));
            num_entity_blocks = header_line(1);
            total_nodes = header_line(2);
            max_node_tag = header_line(4);
            
            % Pre-allocate a matrix to store node coordinates.
            % Using NaN helps identify if any node tags were missed.
            % We use max_node_tag for direct indexing.
            points_matrix = NaN(max_node_tag, 2);

            % Prepare containers for special entity nodes
            nodes_on_verts = zeros(0,4); % [X, Y, node-number, entityTag] for entityDim==0
            nodes_on_edges = zeros(0,4); % [X, Y, node-number, entityTag] for entityDim==1

            % Process each entity block within the $Nodes section
            for i = 1:num_entity_blocks
                % The block header line contains:
                % entityDim entityTag parametric numNodesInBlock
                block_info = str2num(fgetl(fid));
                entity_dim = block_info(1);
                entity_tag = block_info(2);
                num_nodes_in_block = block_info(4);
                node_nums = zeros(num_nodes_in_block, 1);

                % Read all node tags in this block
                for j = 1:num_nodes_in_block
                    % Each node tag line contains a single integer nodeTag
                    node_nums(j) = str2num(fgetl(fid));
                end

                % Read the coordinates for these nodes and collect per-entity data
                for j = 1:num_nodes_in_block
                    coords = str2num(fgetl(fid));
                    xy = coords(1:2);
                    node_tag = node_nums(j);
                    % Store the X and Y coordinates in the points matrix
                    points_matrix(node_tag, :) = xy;

                    % Save nodes grouped by entityDim where requested
                    if entity_dim == 0
                        % vertex nodes: [X, Y, node-number, entityTag]
                        nodes_on_verts(end+1, :) = [xy, node_tag, entity_tag];
                    elseif entity_dim == 1
                        % edge nodes: [X, Y, node-number, entityTag]
                        nodes_on_edges(end+1, :) = [xy, node_tag, entity_tag];
                    end
                end
                    
                    
                % % Read all the node tags in this block first
                % node_tags = fscanf(fid, '%d', [1, num_nodes_in_block]);
                
                % % Then, read all the coordinates (x, y, z) for this block
                % coords = fscanf(fid, '%f', [3, num_nodes_in_block])';
                
                % % Map the coordinates to their corresponding tags in our matrix
                % % We only store the X and Y coordinates (columns 1 and 2)
                % points_matrix(node_tags, :) = coords(:, 1:2);
            end
            
            mesh.Points = points_matrix;
            % Attach collected entity nodes
            mesh.nodes_on_verts = nodes_on_verts;
            mesh.nodes_on_edges = nodes_on_edges;
            
            % Ensure we read past the $EndNodes line
            while ~strcmp(current_line, '$EndNodes')
                current_line = fgetl(fid);
                if ~ischar(current_line), break; end
            end
        end
        
        % --- 4. Parse the $Elements Section ---
        if strcmp(current_line, '$Elements')
            % First line after header has overall element info
            % Format: numEntityBlocks numElements minElementTag maxElementTag
            header_line = str2num(fgetl(fid));
            num_entity_blocks = header_line(1);
            
            % Use a cell array to temporarily store connectivity lists,
            % as we only want to keep the triangles.
            element_blocks = cell(num_entity_blocks, 1);

            % Process each entity block
            for i = 1:num_entity_blocks
                % Block header line:
                % entityDim entityTag elementType numElementsInBlock
                block_info = str2num(fgetl(fid));
                element_type = block_info(3);
                num_elements_in_block = block_info(4);

                % We only care about 3-node triangles (elementType == 2)
                if element_type == 2
                    % Preallocate storage for this block's elements
                    block_elems = zeros(num_elements_in_block, 3);
                    % Read each element line and parse integers
                    for j = 1:num_elements_in_block
                        % Expect line format: elemTag node1 node2 node3
                        nums = sscanf(fgetl(fid), '%d');
                        % Defensive: ensure we have at least 4 integers
                        if numel(nums) >= 4
                            block_elems(j, :) = nums(2:4)';
                        else
                            error('Unexpected element line format in triangle block at block %d, line %d', i, j);
                        end
                    end
                    element_blocks{i} = block_elems;
                else
                    % Non-triangle element types: collect their tags if desired,
                    % but for now we simply skip over the lines while preserving
                    % the file pointer by reading each line.
                    for j = 1:num_elements_in_block
                        fgetl(fid);
                    end
                    % Leave element_blocks{i} empty for non-triangle blocks
                    element_blocks{i} = [];
                end
            end
            
            % Consolidate all the collected triangle blocks into one final matrix
            % Only concatenate non-empty blocks to avoid errors from [] cells
            non_empty = ~cellfun(@(c) isempty(c), element_blocks);
            if any(non_empty)
                mesh.ConnectivityList = vertcat(element_blocks{non_empty});
            else
                mesh.ConnectivityList = zeros(0, 3);
            end
            
            % Ensure we read past the $EndElements line
            while ~strcmp(current_line, '$EndElements')
                current_line = fgetl(fid);
                if ~ischar(current_line), break; end
            end
        end
        
        % Move to the next line in the file
        current_line = fgetl(fid);
    end
    
    % --- 5. Cleanup and Close ---
    fclose(fid);

    % Optional: Remove any all-NaN rows from Points matrix if the node
    % numbering is sparse (e.g., tags are 1, 2, 5, 10...). This keeps only
    % the nodes that were actually defined in the file.
    mesh.Points = mesh.Points(~all(isnan(mesh.Points), 2), :);

end

% -------------------------------------------------------------------------
% Notes & optional code snippets: capturing element types other than 2
% -------------------------------------------------------------------------
% The parser above intentionally skips non-triangle element blocks and
% sets their corresponding entries in `element_blocks` to []. This keeps
% the reading logic simple and safe while ensuring the file pointer is
% advanced correctly. If you'd like to keep element information for
% element types other than 2 (for example, elementType == 1 which often
% corresponds to 2-node lines), below are several copy-paste-ready
% approaches you can add into the element parsing loop above.

% 1) Store only element tags for elementType == 1 (lightweight)
% --------------------------------------------------------------
% % Before the entity-block loop add:
% type1_tags = cell(num_entity_blocks, 1);
% 
% % Inside the entity-block loop, replace the else branch with:
% elseif element_type == 1
%     type1_tags{i} = zeros(num_elements_in_block, 1);
%     for j = 1:num_elements_in_block
%         nums = sscanf(fgetl(fid), '%d');
%         if isempty(nums)
%             error('Unexpected empty line in elementType 1 block %d, element %d', i, j);
%         end
%         type1_tags{i}(j) = nums(1); % store element tag only
%     end
%     element_blocks{i} = [];
% 
% % After parsing, consolidate:
% type1_non_empty = ~cellfun(@isempty, type1_tags);
% if any(type1_non_empty)
%     mesh.ElementType1Tags = vertcat(type1_tags{type1_non_empty});
% else
%     mesh.ElementType1Tags = zeros(0,1);
% end

% 2) Store full connectivity for elementType == 1 (line elements)
% --------------------------------------------------------------
% % Before the loop:
% type1_blocks = cell(num_entity_blocks, 1);
% 
% % Inside entity-block loop:
% elseif element_type == 1
%     block_elems = zeros(num_elements_in_block, 2); % 2 nodes per line element
%     for j = 1:num_elements_in_block
%         nums = sscanf(fgetl(fid), '%d');
%         if numel(nums) >= 3
%             block_elems(j, :) = nums(2:3)'; % node1,node2
%         else
%             error('Unexpected element line format in line block %d element %d', i, j);
%         end
%     end
%     type1_blocks{i} = block_elems;
%     element_blocks{i} = [];
% 
% % After parsing, consolidate:
% type1_non_empty = ~cellfun(@isempty, type1_blocks);
% if any(type1_non_empty)
%     mesh.LineConnectivity = vertcat(type1_blocks{type1_non_empty}); % (M x 2)
% else
%     mesh.LineConnectivity = zeros(0,2);
% end

% 3) General and robust approach (recommended if element lines contain
%    extra metadata or you expect many element types)
% --------------------------------------------------------------
% % Create a small lookup for number of node indices per element type
% elementTypeNumNodes = containers.Map('KeyType','double','ValueType','double');
% elementTypeNumNodes(1) = 2; % line
% elementTypeNumNodes(2) = 3; % triangle
% elementTypeNumNodes(4) = 4; % tetra (example)
% % Add more types as needed for your meshes.
% 
% % Inside the entity-block parsing logic, for each element line do:
% nums = sscanf(fgetl(fid), '%d');
% if ~isempty(nums)
%     % The format may vary; many gmsh formats include tags and place
%     % node indices at the end of the line. Adapt indexing accordingly.
%     if isKey(elementTypeNumNodes, element_type)
%         nnodes = elementTypeNumNodes(element_type);
%         % Defensive: ensure there are enough numbers to extract node ids
%         if numel(nums) >= (1 + nnodes)
%             node_ids = nums(end - nnodes + 1 : end)';
%             % Store node_ids into a type-specific cell, e.g.
%             % type_blocks{element_type}{i}(j, :) = node_ids;
%         else
%             error('Element line for type %d does not contain expected node ids', element_type);
%         end
%     else
%         % Unknown element type: skip or collect raw nums for later
%     end
% end

% -------------------------------------------------------------------------
% End of optional snippets
% -------------------------------------------------------------------------
