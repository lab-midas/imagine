% Function to compute the (3D) graytone spatial dependence matrix (GTSDM) 
% for an ROI and image. 
%
% Input is the logical ROI sub-volume (the bounding box around the ROI defined
% by 'determine_ROI_3D_connectivity_2'), the (similarly sized) image volume, 
% the binary connectivity map for the ROI sub-volume, and the number of
% desired grayscale image value bins, N, to be used in the computations. 
%
% Output is an NxNx13 array, GTSDM, where each GTSDM(:,:,n) is the matrix
% corresponding to a certain direction. Directions are taken from the 13
% unique directions of 26-connectivity in 3D. These are indexed here as:
%
% dirs = zeros(3,3,3);
% dirs(:) = 1:27;
%
% Then each index in 'dirs' corresponds to a direction (from the center
% [2,2,2] of 'dirs').
%
% USAGE:
%
% GTSDM = compute_3D_GTSDM_2(ROI_vol,img_vol,binary_dir_connectivity,num_img_values)
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






function GTSDM = compute_3D_GTSDM_2(ROI_vol,img_vol,binary_dir_connectivity,num_img_values)

%% Define the directions for connectivity


% These are the directions for connectivity:
dir_indices = zeros(3,3,3);
dir_indices(:) = 1:27;


%% The connectivity loop:

% Structure to hold the GTSDM matrices for each of the 13 directions:
GTSDM = zeros(num_img_values,num_img_values,13);

% ndgrid for the voxel offsets:
[nd_ro , nd_co , nd_so] = ndgrid(-1:1,-1:1,-1:1);

ROI_voxel_indices = find(ROI_vol);



% Loop over each voxel in the ROI sub-volume:
for this_ROI_voxel = 1:length(ROI_voxel_indices)
    
    % The index of this voxel in the sub-volume:
    this_voxel_index = ROI_voxel_indices(this_ROI_voxel);
    
    % Determine the [r,c,s] of this voxel:
    [r,c,s] = ind2sub(size(ROI_vol),this_voxel_index);
    
    % Determine the connected directions to loop over:
    conn_dirs = dir_indices(binary_dir_connectivity{this_ROI_voxel});
    
    % We only care about the first 13 directions, all others are redundant:
    conn_dirs = conn_dirs(conn_dirs<=13);


    % Loop over each direction indicated:
    for this_dir_index = 1:length(conn_dirs)
        
        this_dir = conn_dirs(this_dir_index);
        
        % Determine the voxel offsets for this direction:
        ro = nd_ro(this_dir);
        co = nd_co(this_dir);
        so = nd_so(this_dir);
        
        % Increment the GTSDM matrix for this direction:
        GTSDM(img_vol(r,c,s),img_vol(r+ro,c+co,s+so),this_dir) = ...
                GTSDM(img_vol(r,c,s),img_vol(r+ro,c+co,s+so),this_dir) + 1;

    end % Loop over directions for this voxel
end % loop over voxels in the ROI sub-volume


% Each GTSDM matrix is symmetric, independent of +/- direction, so add it
% to its transpose:
for this_dir_index = 1:13
    GTSDM(:,:,this_dir_index) = GTSDM(:,:,this_dir_index) + GTSDM(:,:,this_dir_index)' ;
end


%%% Final END statement:
end

