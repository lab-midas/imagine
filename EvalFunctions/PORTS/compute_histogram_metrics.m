% Function to compute the histogram-based image texture metrics. Input is
% the histogram of the number of ROI voxels with a given value. Output is a
% vector of the six metrics:
%
% (1) Mean
% (2) Variance
% (3) Skewness
% (4) Kurtosis
% (5) Energy
% (6) Entropy
%
% The definitions of these metrics are taken from:
%
% 'Texture Analysis Methods ? A Review'
% Andrzej Materka and Michal Strzelecki (1998)
%
% Equations 4.4 through 4.9. 
%
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






function metrics_vect = compute_histogram_metrics(vox_val_probs,num_img_values)


%%
if nargin == 0
    metrics_vect = {'Histogram - Mean' ; ...
                    'Histogram - Variance' ; ...
                    'Histogram - Skewness' ; ...
                    'Histogram - Kurtosis' ; ...
                    'Histogram - Energy' ; ... 
                    'Histogram - Entropy' };
    return
end

%%

% Placeholder for the output:
metrics_vect = zeros(6,1);


%%% Overhead:

% The numerical values of each histogram bin:
vox_val_indices = (1:num_img_values)';

% The indices of non-empty histogram bins:
hist_nz_bin_indices = find(vox_val_probs);



%%% (1) Mean 
metrics_vect(1) = sum(vox_val_indices .* vox_val_probs);



%%% (2) Variance
metrics_vect(2) = sum( ((vox_val_indices - metrics_vect(1)).^2) .* vox_val_probs );


%%%%% IF standard variance is zero, so are skewness and kurtosis:
if metrics_vect(2) > 0
    
    %%% (3) Skewness
    metrics_vect(3) = sum( ((vox_val_indices - metrics_vect(1)).^3) .* vox_val_probs ) / (metrics_vect(2)^(3/2));



    %%% (4) Kurtosis
    metrics_vect(4) = sum( ((vox_val_indices - metrics_vect(1)).^4) .* vox_val_probs ) / (metrics_vect(2)^2);
    metrics_vect(4) = metrics_vect(4) - 3;
    
else
    
    %%% (3) Skewness
    metrics_vect(3) = 0;
    
    
    %%% (4) Kurtosis
    metrics_vect(4) = 0;
    
end
    
    



%%% (5) Energy
metrics_vect(5) = sum( vox_val_probs .^2 );



%%% (6) Entropy (NOTE: 0*log(0) = 0 for entropy calculations)
metrics_vect(6) = -sum( vox_val_probs(hist_nz_bin_indices) .* log(vox_val_probs(hist_nz_bin_indices)) );



%%% Final END statement:
end








