clc;        % Clear command window
clear;      % Clear workspace variables
close all;  % Close all figures

%% LOAD FINITE ELEMENT DATA FILES
% Load precomputed matrices for finite element analysis:
% D_L  : Shape function derivatives in local coordinates
% N_L  : Shape function derivatives in global coordinates  
% Coef : Element coefficient matrix for scaling
load('D_L.mat');
load('N_L.mat');
load('Coef.mat');

%% IMPORT AND PROCESS MESH
% Read the mesh file and create the initial mesh structure
Raw_Mesh = read_msh_experimental('Mesh_02.msh');

% Enhance linear mesh to quadratic (2nd order) elements
Quad_Mesh = enhanceMeshToQuadratic(Raw_Mesh);

% Apply Reverse Cuthill-McKee reordering to reduce matrix bandwidth
Opt_Mesh = applyRCM_2(Quad_Mesh);

% Initialize parameters for the finite element analysis
params = Initial_Values(Raw_Mesh, Opt_Mesh);

%% VISUALIZE THE MESH
% Plot the quadratic mesh for visual inspection
plotQuadraticMesh(Opt_Mesh);

%% CALCULATE HALF-BANDWIDTH
% Compute half-bandwidth for both original and reordered meshes
RAW_HBW = calculateHBW(Quad_Mesh);    % Half-bandwidth of original mesh
RCM_HBW = calculateHBW(Opt_Mesh);     % Half-bandwidth of RCM-optimized mesh

% Display bandwidth comparison results
fprintf('Bandwidth Comparison:\n');
fprintf('Original mesh half-bandwidth: %d\n', RAW_HBW);
fprintf('RCM-optimized mesh half-bandwidth: %d\n', RCM_HBW);
fprintf('Bandwidth reduction: %.1f%%\n', (1 - RCM_HBW/RAW_HBW)*100);

%% ASSEMBLE GLOBAL MATRICES
% Assemble the global stiffness matrix K and force vector F
tic;
[K, F] = AssembleyMatrix(D_L, params, Raw_Mesh, Opt_Mesh);
assembly_time = toc;
fprintf('Assembly time: %.2f seconds\n', assembly_time);

%% DISPLAY ASSEMBLY RESULTS
fprintf('\nAssembly Results:\n');
fprintf('Global stiffness matrix size: %d x %d\n', size(K, 1), size(K, 2));
fprintf('Number of non-zero entries in K: %d\n', nnz(K));
fprintf('Force vector size: %d x %d\n', size(F, 1), size(F, 2));

% Display sparsity pattern of the stiffness matrix
figure;
spy(K);
title('Sparsity Pattern of Global Stiffness Matrix K');
xlabel('Column index');
ylabel('Row index');
grid on;