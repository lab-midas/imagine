% This script illustrates how the PORTS texture computation functions are
% used. 
%
% In this case, we are computing the texture metrics on an entire
% 3D image volume. The image volume has matlab variable name 'img_vol' in 
% this script. 
%
% The co-occurance and neighborhood difference matrices cannot
% be computed at the edge of the image volume. For this reason, we set the
% mask to be the entire volume except those edge voxels. Note that if we 
% were to use co-occurance with a 2-voxel distance, then we sould need to 
% omit the two outermost layers of the mask.
%
% For consistency, we compute the histogram-based and Zone Size metrics on
% the same set of voxels.
%
%
% This script is a modification of 'example_script_1.m', and changes are
% noted in the comments by three spaced comment characters: '% % % '.
%



%% Data Paths

Add the matlab path to the PORTS package:
PORTS_DIR = '/User/userdir/matlab/PORTS_20160218';
addpath(PORTS_DIR);



%% Texture Parameters


% Choose the number of distinct graytone values to use for computing 
% texture metrics:
num_img_values = 64;



%% Get the names of all metrics into a cell array:

% This step creates a cell structure with all of the metric names. Calling
% a 'compute_*_metrics.m' function without any argument returns a cell 
% structure with the names of the metrics that function computes.


% Put all of the computed metric names into a single list. There are 42
% texture metrics computed in this script:
metric_names = [compute_histogram_metrics() ; ...
                compute_GTSDM_metrics() ; ...
                compute_NGTDM_metrics() ; ...
                compute_zone_size_metrics() ];

            
% Number the metric names to make it easy on the user:
temp_metric_names = cell(size(metric_names));
for this_metric = 1:size(metric_names,1)
    temp_metric_names{this_metric} = sprintf('(%d) %s',this_metric,metric_names{this_metric});
end

metric_names = temp_metric_names;


% Clear unused variable:
clear temp_metric_names

        

%% Overhead Computations for the Masks


% The function 'determine_ROI_3D_connectivity.m' is a pre-processing step
% to speed up computation of the co-occurance and neighborhood-dependence
% matrices. It determines which voxels in the mask are connected and how 
% they are connected. It also determines a bounding box around the mask 
% that can be used to speed up computations.


% % % % Determine connectivity and bounding box of this ROI:
% % % [bounding_box,ROI_conn_3D_6,ROI_conn_3D_26,binary_dir_connectivity] = ...
% % %     determine_ROI_3D_connectivity(mask_vol);
% % % 

% % % We are using the entire image volume as the ROI, so we do not need to
% % % compute the voxel connectivity or bounding box. In this case, we set 
% % % the voxel connectivity to be empty, and do not compute the sub-volumes.
% % % NOTE: this means that we are using 'img_vol' instead of 'img_vol_subvol'
% % % (used in 'examplescript_1.m' as an argument for the computations below.
binary_dir_connectivity = [];



% % % % Take the ROI sub-volume within the bounding box:
% % % mask_vol_subvol = mask_vol(bounding_box(1,1):bounding_box(1,2) , ...
% % %                            bounding_box(2,1):bounding_box(2,2) , ...
% % %                            bounding_box(3,1):bounding_box(3,2) );      
% % % 
% % %                     
% % % % Now take the image sub-volume that corresponds to this mask:
% % % img_vol_subvol = img_vol(bounding_box(1,1):bounding_box(1,2) , ...
% % %                          bounding_box(2,1):bounding_box(2,2) , ...
% % %                          bounding_box(3,1):bounding_box(3,2) );      





% Logical mask for the full image volume:
mask_vol = true(size(img_vol));

% Cut the six faces off:
mask_vol(1,:,:) = 0; % % % For 2-separation voxels, use
mask_vol(:,1,:) = 0; % % % mask_vol(1:2,:,:) = 0; etc.
mask_vol(:,:,1) = 0;

mask_vol(end,:,:) = 0;
mask_vol(:,end,:) = 0;
mask_vol(:,:,end) = 0;


% GTSDM and NGTDM functions both need to compute the indices for the voxels
% in the volume. It is faster to do this once up front and pass it into the
% functions:
mask_indices = find(mask_vol);
[mask_rows,mask_cols,mask_slcs] = ind2sub(size(mask_vol),mask_indices);

% The variable 'mask_rcs' is an array with 3 columns: {row,column,slice} of
% each voxel in the logical mask.
mask_rcs = [mask_rows,mask_cols,mask_slcs];


                   
%% Texture Metric Computation 


% Create a column-vector placeholder for the 42 texture metrics:
texture_metrics = zeros(42,1);



% Determine the number of voxels in the ROI. This is used to compute the
% histogram-based probabilities and also in the Size-Zone metrics
% computations:
num_ROI_voxels = length(find(mask_vol));




%%% Discretize the image volume to the desired number of graytones. The
%%% PORTS functions require the image voxel values to be {1,2,3,...,N}. 


% % % Find the min and max for the entire image volume rather than just the
% % % mask. We do this because the largest voxel value in the image may be
% % % outside the mask.
img_min = min(img_vol(:)); 
img_max = max(img_vol(:)); 


% Rescale to image volume to [0,N]:
img_vol = num_img_values .* (img_vol - img_min)/(img_max - img_min) ;

% Discretize and add 1 to get values {1,2,...,N+1}:
img_vol = floor(img_vol) + 1;

% The max value is currently one higher than it should be (N+1), so put 
% those voxels at the max value:
img_vol(img_vol==num_img_values+1) = num_img_values;




%%%%%
%%%%% Histogram-based computations:
%%%%%

% % % NOTE: The histogram is only being computed on the mask, not the
% % % entire image volume.

% Compute the histogram of the ROI and probability of each voxel value:
vox_val_hist = zeros(num_img_values,1);
for this_vox_value = 1:num_img_values
    vox_val_hist(this_vox_value) = length(find((img_vol == this_vox_value) & (mask_vol == 1) ));
end

% Compute the relative probabilities from the histogram:
vox_val_probs = vox_val_hist / num_ROI_voxels;


% Compute the histogram_based metrics:
texture_metrics(1:6) = compute_histogram_metrics(vox_val_probs,num_img_values);




%%%%%
%%%%% GTDSM (Co-occurance) Matrix calculations:
%%%%%


% % % NOTE: We are using the function 'compute_3D_GTSDM_full_vol.m', which
% % % is faster on whole image volumes. The 'binary_dir_connectivity'
% % % variable is empty.


% Create the Gray-Tone-Spatial-Dependence-Matrix (GTSDM):
GTSDM = compute_3D_GTSDM_full_vol(img_vol,num_img_values,mask_rcs);


% It is common to compute the mean value over the 13 directions (for
% distance-1 voxels). The following loop computes the metrics for each
% direction:
GTSDM_metrics = zeros(13,20);
for this_direction = 1:13
    % Compute the metrics for this combination:
    GTSDM_metrics(this_direction,:) = compute_GTSDM_metrics(GTSDM(:,:,this_direction));
end

% Now take the mean texture metric value over the all directions:
texture_metrics(7:26) = mean(GTSDM_metrics,1);




%%%%%
%%%%% NTGDM Matrices and metrics
%%%%%


% % % NOTE: We are using 'compute_3D_NGTDM_full_vol.m', which is faster on
% % % whole image volumes. The 'binary_dir_connectivity' variable is empty.


% Create the Neighborhood-Gray-Tone-Difference-Matrix(NGTDM):
[NGTDM,vox_occurances_NGD26] = compute_3D_NGTDM_full_vol(img_vol,num_img_values,mask_rcs);


% Compute NGTDM metrics:
texture_metrics(27:31) = compute_NGTDM_metrics(NGTDM,num_img_values,vox_occurances_NGD26);




%%%%%
%%%%% Zone Size matrix and Metrics:
%%%%%

% Create the Zone Size Matrix:
GLZSM = compute_GLZSM(mask_vol,img_vol,num_img_values);

% Compute the Zone Size Metrics:
texture_metrics(32:42) = compute_zone_size_metrics(GLZSM,num_ROI_voxels);








