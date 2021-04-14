% Function to compute the five metrics for the NGTDM (Amadasun 1989)
% Input is the NGTDM matrix.
% Output is a vector with the five metrics values:
%
% (1) Coarseness
% (2) Contrast
% (3) Busyness
% (4) Complexity
% (5) Texture Strength
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





function metrics_vect = compute_NGTDM_metrics(NGTDM,num_img_values,vox_occurances_NGD26)


%%
if nargin == 0
    metrics_vect = {'NGTDM - Coarseness' ; ...
                    'NGTDM - Contrast' ; ...
                    'NGTDM - Busyness' ; ...
                    'NGTDM - Complexity' ; ...
                    'NGTDM - Texture Strength' };
    return
end
% Placeholder for the metrics:
metrics_vect = zeros(5,1);

% Compute the probability of each voxel value:
vox_val_probs = vox_occurances_NGD26 / sum(vox_occurances_NGD26);

% The non-zero indices for the voxel value probabilities:
vox_prob_nz = find(vox_val_probs > 0);

% number of unique graytones in image:
N_g = length(find(vox_occurances_NGD26 > 0));


%%% ndgrids ('nd_' prefix) used later:

% Row (_r) and Column (_c) indices:
[nd_r , nd_c] = ndgrid(1:num_img_values,1:num_img_values);

% Non-zeros_indices('nz_') for rows numbers (_r) and
% probability matrix rows (_pr)
[nd_nz_r , nd_nz_c] = ndgrid(vox_prob_nz,vox_prob_nz);
[nd_nz_p_r , nd_nz_p_c] = ndgrid(vox_val_probs(vox_prob_nz),vox_val_probs(vox_prob_nz));

% Non-zeros rows/cols of the outer product of the NGTDM with
% itself:
[nd_nz_NGTDMop_r , nd_nz_NGTDMop_c] = ndgrid(NGTDM(vox_prob_nz),NGTDM(vox_prob_nz));








%%

%%% (1) Coarseness
metrics_vect(1) = sum( vox_val_probs .* NGTDM );

% It's the reciprocal, so test for zero denominator:
if metrics_vect(1) == 0
    metrics_vect(1) = Inf;
else
    metrics_vect(1) = 1/metrics_vect(1);
end



%%% (2) Contrast
if N_g > 1 % There is some voxel color differences, so perform calculations as normal:
    % The first term in equation (4):
    first_term_mat = (vox_val_probs * vox_val_probs') .* ( (nd_r-nd_c).^2 );
    first_term_val = sum(first_term_mat(:)) / (N_g * (N_g-1) );

    % The second term in equation (4). Note that the 3D computation
    % necessitates normalization by the number of voxels instead of the n^2 that appears in
    % equation (4). 
    second_term_val = sum(NGTDM) / sum(vox_occurances_NGD26);

    % Record the value:
    metrics_vect(2) = first_term_val * second_term_val;
    
else % There is only a single color, so no contrast to compute, so set to negative:
        metrics_vect(2) = -1;
end
    


%%% (3) Busyness
% NOTE: The denominator equals zero in the paperAmadasun 1989. Absolute value inside the
% double-sum is given here, in accordance with 
%
% Texture Analysis Methods ? A Review
% Andrzej Materka and Michal Strzelecki (1998)
%
first_term = sum(vox_val_probs .* NGTDM);

second_term_mat = (nd_nz_r .* nd_nz_p_r) - (nd_nz_c .* nd_nz_p_c);
second_term = sum(abs(second_term_mat(:)));

if second_term == 0
    metrics_vect(3) = Inf;
else 
    metrics_vect(3) = first_term / second_term;
end




%%% (4) Complexity
first_term_num = abs(nd_nz_r - nd_nz_c);
first_term_den = nd_nz_p_r + nd_nz_p_c;

second_term = (nd_nz_p_r .* nd_nz_NGTDMop_r) + (nd_nz_p_c .* nd_nz_NGTDMop_c);


if second_term == 0
    metrics_vect(4) = Inf;
else
    tmp = first_term_num(:) .* second_term(:) ;
    tmp = sum(tmp ./ first_term_den(:)) ;
    metrics_vect(4) = tmp / sum(vox_occurances_NGD26) ;
end



%%% (5) Texture Strength
first_term_mat = (nd_nz_p_r+nd_nz_p_c) .* ( (nd_nz_r - nd_nz_c) .^2 );
first_term = sum(first_term_mat(:));
second_term = sum(NGTDM);

if second_term == 0
    metrics_vect(5) = Inf;
else
    metrics_vect(5) = first_term / second_term ;
end




%%% Final END statement:
end






