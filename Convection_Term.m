function H_e = Convection_Term(H, N_L, Coef)
%% Initialize Matrices
Conv = cell(6, 6);  % Cell array to store convection matrices
H_e = zeros(6);     % Global convection matrix (6x6)
%% Compute Convection Matrices
for i = 1:6
    for j = 1:6
        % Compute outer product of shape function derivatives (x-component)
        Conv{i, j} = N_L{1, i}(1, :).' * N_L{1, j}(1, :);

        % Apply Heaviside function weighting
        Conv{i, j} = Conv{i, j} * H(j) * H(i);

        %% Scale by Coefficient Matrix (Element-wise Division)
        for m = 1:10
            for n = 1:10
                Conv{i, j}(m, n) = Conv{i, j}(m, n) * (1 / Coef(m, n));
            end
        end

        %% Sum Contributions to Global Matrix
        H_e(i, j) = sum(sum(Conv{i, j}));
    end
end