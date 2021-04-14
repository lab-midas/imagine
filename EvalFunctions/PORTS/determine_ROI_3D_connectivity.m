% Function to generate connectivity maps for an ROI. This is pre-processing
% step needed for computing the NGTDM and other needed structures.
%
% The input is a logical array of the ROI for the image to be analyzed. 
%
% The output is a bounding box around the ROI (min row, max row, etc.), a
% cell of the 6-connected voxels for each index in the ROI, another similar
% cell with the 26-connected voxels, and a 3x3x3 logical map of the connectivity
% around each voxel. 
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




function [bounding_box,ROI_conn_3D_6,ROI_conn_3D_26,binary_dir_connectivity] = ...
    determine_ROI_3D_connectivity(ROI_full_logical)


%% Find bounding box around the ROI:

ROI_full_ind = find(ROI_full_logical);
[ROI_full_row,ROI_full_col,ROI_full_slc] = ind2sub(size(ROI_full_logical),ROI_full_ind);

bounding_box = [min(ROI_full_row) , max(ROI_full_row) ; ...
                min(ROI_full_col) , max(ROI_full_col) ; ...
                min(ROI_full_slc) , max(ROI_full_slc) ];

%% Take the sub-volume and compute the indices:

% The sub-volume:
ROI_vol = ROI_full_logical(bounding_box(1,1):bounding_box(1,2) , ...
                      bounding_box(2,1):bounding_box(2,2) , ...
                      bounding_box(3,1):bounding_box(3,2) );


% Re-compute the indices for the sub-volume:                  
ROI_ind = find(ROI_vol);
[ROI_row,ROI_col,ROI_slc] = ind2sub(size(ROI_vol),ROI_ind);                  


%% Compute the various connectivities:

% 3D connectivities:
ROI_conn_3D_6           = cell(size(ROI_ind));
ROI_conn_3D_26          = cell(size(ROI_ind));
binary_dir_connectivity = cell(size(ROI_ind));


% An ndgrid for this sub-volume to extract indices from:
[sub_vol_nd_rows,sub_vol_nd_cols,sub_vol_nd_slcs] = ndgrid( 1:size(ROI_vol,1) , 1:size(ROI_vol,2) , 1:size(ROI_vol,3) );


%%% Loop over voxels in the ROI:
for this_voxel_index = 1:length(ROI_ind)
    
    % The [row,column,slice] of the current voxel:
    this_row = ROI_row(this_voxel_index);
    this_col = ROI_col(this_voxel_index);
    this_slc = ROI_slc(this_voxel_index);
    
    
    % Define the full 3D neighborhood (26) around this voxel:
    NGD_row_min = max(this_row-1,1);
    NGD_row_max = min(this_row+1,size(ROI_vol,1));
    NGD_col_min = max(this_col-1,1);
    NGD_col_max = min(this_slc+1,size(ROI_vol,3));
    NGD_slc_min = max(this_slc-1,1);
    NGD_slc_max = min(this_slc+1,size(ROI_vol,3));
    
    % Placeholders for 3D binary neighborhood masks:
    ROI_conn_3D_6_mask  = zeros(size(ROI_vol));
    ROI_conn_3D_26_mask = zeros(size(ROI_vol));
    
    
    % Define the full 26-connected neighborhood around this voxel:
    ROI_conn_3D_26_mask(NGD_row_min:NGD_row_max , NGD_col_min:NGD_col_max , NGD_slc_min:NGD_slc_max ) = 1;
    ROI_conn_3D_26_mask(this_row,this_col,this_slc) = 0;
    
    
    % Define the 6-connected neighborhood around this voxel:
    if this_row > 1
        ROI_conn_3D_6_mask(this_row-1,this_col,this_slc) = 1;
    end
    if this_row < size(ROI_vol,1)
        ROI_conn_3D_6_mask(this_row+1,this_col,this_slc) = 1;
    end
    
    if this_col > 1
        ROI_conn_3D_6_mask(this_row,this_col-1,this_slc) = 1;
    end
    if this_col < size(ROI_vol,2)
        ROI_conn_3D_6_mask(this_row,this_col+1,this_slc) = 1;
    end
    
    if this_slc > 1
        ROI_conn_3D_6_mask(this_row,this_col,this_slc-1) = 1;
    end
    if this_slc < size(ROI_vol,3)
        ROI_conn_3D_6_mask(this_row,this_col,this_slc+1) = 1;
    end
    
        
        
    % For each (6 and 26) NGD, multiply by the ROI logical mask (ROI_vol) to
    % get the indices needed. These are stored in [row,column,slice,index]
    % format:
    NGD_indices_6 = find(ROI_vol .* ROI_conn_3D_6_mask);
    ROI_conn_3D_6{this_voxel_index} = [sub_vol_nd_rows(NGD_indices_6) , sub_vol_nd_cols(NGD_indices_6) , ...
                                       sub_vol_nd_slcs(NGD_indices_6) , NGD_indices_6 ];
                                   
                                   
    NGD_indices_26 = find(ROI_vol .* ROI_conn_3D_26_mask);
    ROI_conn_3D_26{this_voxel_index} = [sub_vol_nd_rows(NGD_indices_26) , sub_vol_nd_cols(NGD_indices_26) , ...
                                       sub_vol_nd_slcs(NGD_indices_26) , NGD_indices_26 ];
        
        
    %%% Now compute the local binary connectivities in 26 directions:
    
    % Placeholder:
    tmp_binary_dir_connectivity = zeros(3,3,3);
    
    % Loop over the 3x3x3 neighborhood to populate this indicator matrix:
    for NGD_slc_offset = -1:1
        for NGD_col_offset = -1:1
            for NGD_row_offset = -1:1
                
                % If this voxel is a neighborhood voxel, record it. It must
                % be within the volume:
                if ( ( 1 <= this_row+NGD_row_offset && this_row+NGD_row_offset <= size(ROI_vol,1) ) && ...
                     ( 1 <= this_col+NGD_col_offset && this_col+NGD_col_offset <= size(ROI_vol,2) ) && ...
                     ( 1 <= this_slc+NGD_slc_offset && this_slc+NGD_slc_offset <= size(ROI_vol,3) ) )
                 
                    % The voxel must be part of the ROI:
                    if ROI_vol(this_row+NGD_row_offset,this_col+NGD_col_offset,this_slc+NGD_slc_offset)
                        tmp_binary_dir_connectivity(NGD_row_offset+2,NGD_col_offset+2,NGD_slc_offset+2) = 1;
                    end
                end
                
                
            end
        end
    end % END populating the directional neighborhood indicator matrix
    
    % Convert to logical for ease of use:
    binary_dir_connectivity{this_voxel_index} = logical(tmp_binary_dir_connectivity);
    
end % END loop over ROI voxel == 1



%%% Final END statement:
end


