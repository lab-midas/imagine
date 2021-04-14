% Function to compute the Neighborhood Gray-Tone Difference Matrix (NGTDM)
% from Amadsun (1989). 
%
% Input image has values {1,...,N}
%
% Output is the NGTDM and a vector of the number of times a voxel value
% occured and had a full neighborhood.




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





function [NGTDM,vox_occurances_NGD26] = compute_3D_NGTDM(ROI_vol,img_vol,binary_dir_connectivity,num_img_values)


% Placeholder for the NGTDM and number of occurances with full NGDs: 
NGTDM = zeros(num_img_values,1);
vox_occurances_NGD26 = zeros(num_img_values,1);

% Record the indices of the voxels used in the ROI:
ROI_voxel_indices = find(ROI_vol);


% Loop over each voxel in the ROI sub-volume:
for this_ROI_voxel = 1:length(ROI_voxel_indices)
    
    % The index of this voxel in the sub-volume:
    this_voxel_index = ROI_voxel_indices(this_ROI_voxel);
    
    % This voxel must have 26 neighbors (plus itself) to be considered:
    if sum(binary_dir_connectivity{this_ROI_voxel}(:)) == 27
        
        % Determine the [r,c,s] of this voxel:
        [r,c,s] = ind2sub(size(ROI_vol),this_voxel_index);
        
        % Compute the mean value around this voxel:
        this_vox_val = img_vol(this_voxel_index);
        vox_ngd = img_vol((r-1):(r+1) , (c-1):(c+1) , (s-1):(s+1));
        vox_ngd_sum = sum(vox_ngd(:)) - this_vox_val;
        vox_ngd_mean = vox_ngd_sum / 26;
        
        % Add this value to the matrix:
        NGTDM(this_vox_val) = NGTDM(this_vox_val) + abs(this_vox_val-vox_ngd_mean);
        
        
        % Increment the number of occurances of this voxel:
        vox_occurances_NGD26(this_vox_val) = vox_occurances_NGD26(this_vox_val) + 1;
        
    
    end % Test for full neighborhood
    
    
end % Loop over ROI voxels





%%% Final END statement:
end





