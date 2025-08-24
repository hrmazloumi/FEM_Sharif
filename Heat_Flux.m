function [Q, q] = Heat_Flux(params)
% HEAT_FLUX Computes heat flux contributions for a finite element analysis.
%
% Inputs:
%   params  - A structure containing:
%             * Q      : Heat source magnitude [W/m^2]
%             * Area   : Element area [m^2]
%             * h      : Convection coefficient [W/m^2-K]
%             * T_inf  : Ambient temperature [K]
%
% Outputs:
%   Q       - 6x1 vector of nodal heat source contributions
%   q       - 6x3 matrix of convection heat flux components

%% Heat Source Contribution (Q)
% Distributes heat source uniformly to 3 nodes (last 3 DOFs)
% Formula: (Q * Area / 3) applied to DOFs 4-6
Q = (params.Q * params.Area / 3) * [0; 0; 0; 1; 1; 1];

%% Convection Heat Flux (q)
% Computes convection components with scaling factors:
% * h * T_inf * sqrt(10)/6 for the triangular distribution
% Matrix layout corresponds to nodal contributions
q = (params.h * params.T_inf * 10^0.5 / 6) * ...
    [1, 0, 1;    % Node 1 contributions
     1, 1, 0;    % Node 2
     0, 1, 1;    % Node 3
     0, 4, 0;    % Node 4 (special weighting)
     0, 0, 4;    % Node 5
     4, 0, 0];   % Node 6
end