% Function to compute metrics for zone size matrices. Input is a zone size
% matrix and the number of pixels (voxels), n_p. 
%
% Output is a vector with 11 entries, taken from:
%
% 'Texture Information in Run-Length Matrices
% by Xiaoou Tang (1998).
%
% The index for each metric is:
% 
% (1) Small Zone Size Emphasis
% (2) Large Zone Size Emphasis
% (3) Low Gray-Level Zone Emphasis
% (4) High Gray-Level Zone Emphasis
% (5) Small Zone / Low Gray Emphasis
% (6) Small Zone / High Gray Emphasis
% (7) Large Zone / Low Gray Emphasis
% (8) Large Zone / High Gray Emphasis
% (9) Gray-Level Non-Uniformity
% (10) Zone Size Non-Uniformity
% (11) Zone Size Percentage
%
%
% If called with no inputs, the ouput is a cell array of the names of each
% metric.
%



%%%%%%%%%%%%
%
% Source code developed by :
% The Imaging Research Laboratory - University of Washington
%
% Copyright 2016 Department of Radiology
% University of Washington
% All Right Reserved
% 
%
%%%%%%%%%%%%


%%%%%%%%%%%%
%
% This software is issued without express warranty, no express guarantee of
% fidelty, and the authors are not responsible for the intended or
% unintended results of usage of this software. Quality verification of
% data obtained using PORTS and results drawn from that data are the sole
% responsibility of the end user.
%
% This software is intended for use in whole, and shall not be altered,
% used in part, or modified without full and proper disclosure by end
% parties. 
%
% All publication that use the PORTS software must cite the version number
% and PORTS website: 
%
% https://nciphub.org/groups/ports
% 
%
%%%%%%%%%%%%

%%%%%%%%%%%%
%
% PET Oncology Radiomics Test Suite (PORTS) version 1.00
% 
% 'determine_ROI_3D_connectivity.m' version 1.00 - 22 Feb. 2016
%
% Programmer: Larry Pierce - University of Washington - lapierce@uw.edu
% 
%
%%%%%%%%%%%%



function metrics_vect = compute_zone_size_metrics(GLZSM,num_ROI_voxels)


%%
if nargin == 0
    metrics_vect = {'GLZSM - Small Zone Size Emphasis' ; ...
                    'GLZSM - Large Zone Size Emphasis' ; ...
                    'GLZSM - Low Gray-Level Zone Emphasis' ; ...
                    'GLZSM - High Gray-Level Zone Emphasis' ; ...
                    'GLZSM - Small Zone / Low Gray Emphasis' ; ... 
                    'GLZSM - Small Zone / High Gray Emphasis' ; ...
                    'GLZSM - Large Zone / Low Gray Emphasis' ; ...
                    'GLZSM - Large Zone / High Gray Emphasis' ; ...
                    'GLZSM - Gray-Level Non-Uniformity' ; ...
                    'GLZSM - Zone Size Non-Uniformity' ; ...
                    'GLZSM - Zone Size Percentage' };
    return
end

%%


%%% NOTE num_ROI_voxels is n_p in the equations from the paper.

% Placeholder for the metrics:
metrics_vect = zeros(11,1);

% ndgrids used for double sums:
[nd_r,nd_c] = ndgrid(1:size(GLZSM,1),1:size(GLZSM,2));

% In every equation, these are squared:
nd_r_sq = nd_r .^2;
nd_c_sq = nd_c .^2;


% For GLZSM, rows are the gray level, columns are the zone sizes, same as
% the paper cited above.


%%% (1) Small Zone Size Emphasis
sum_mat = GLZSM ./ nd_c_sq;
metrics_vect(1) = sum(sum_mat(:));



%%% (2) Large Zone Emphasis
sum_mat = GLZSM .* nd_c_sq;
metrics_vect(2) = sum(sum_mat(:));



%%% (3) Low Gray Emphasis
sum_mat = GLZSM ./ nd_r_sq;
metrics_vect(3) = sum(sum_mat(:));


%%% (4) High Gray Emphasis
sum_mat = GLZSM .* nd_r_sq;
metrics_vect(4) = sum(sum_mat(:));



%%% (5) Small Zone / Low Gray
sum_mat = GLZSM ./ (nd_r_sq .* nd_c_sq);
metrics_vect(5) = sum(sum_mat(:));



%%% (6) Small Zone / High Gray
sum_mat = (GLZSM .* nd_r_sq) ./ nd_c_sq;
metrics_vect(6) = sum(sum_mat(:));


%%% (7) Large Zone / Low Gray
sum_mat = (GLZSM .* nd_c_sq) ./ nd_r_sq;
metrics_vect(7) = sum(sum_mat(:));


%%% (8) Large Zone / High Gray
sum_mat = (GLZSM .* nd_r_sq) .* nd_c_sq;
metrics_vect(8) = sum(sum_mat(:));


%%% (9) Gray-Level Non-Uniformity
metrics_vect(9) = sum(sum(GLZSM,2).^2);


%%% (10) Zone Size Non-Uniformity
metrics_vect(10) = sum(sum(GLZSM,1).^2);


%%%%%
%%%%% All sums are now normalized the n_r
%%%%%
metrics_vect = metrics_vect ./ sum(GLZSM(:));



%%% (11) Zone Size Percentage
metrics_vect(11) = sum(GLZSM(:)) / num_ROI_voxels;

%%% Final END statement:
end







