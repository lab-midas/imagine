% Function to compute the Gray Level Zone Size matrix (GLZSM) for an image
%
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





function GLZSM = compute_GLZSM_1(ROI_vol,img_vol,num_img_values)

% The number of voxels considered in the ROI volume:
num_ROI_vox = length(find(ROI_vol));

% Placeholder for the GLZSM. Presume that the number of zone sizes is the
% number of voxels in the ROI (the max possible size). Later, this will be 
% truncated to fit.
% Rows are the gray level, columns are the zone sizes.
GLZSM = zeros(num_img_values,num_ROI_vox);


% Placeholder for a binary mask for each gray level:
gray_level_mask = zeros(size(img_vol));


% Loop over the gray levels:
for this_img_val = 1:num_img_values
    
    % Zero out the mask:
    gray_level_mask(:) = 0;
    
    % Change the voxels for the current gray level to one:
    gray_level_mask(img_vol == this_img_val & ROI_vol) = 1;
    
    % Compute the connectivity using the built-in matlab function:
    conn_struct = bwconncomp(gray_level_mask , 26);
    
    % Loop over the zones:
    for this_zone_index = 1:conn_struct.NumObjects
        
        this_zone_size = length(conn_struct.PixelIdxList{this_zone_index});
        GLZSM(this_img_val,this_zone_size) = GLZSM(this_img_val,this_zone_size) + 1;
        
    end % Loop over disconnected zones
end % Loop over gray level values


% Truncate the matrix to fit the max zone size:
last_col = find(sum(GLZSM,1),1,'last');
GLZSM = GLZSM(:,1:last_col);


%%% Final END statement:
end






