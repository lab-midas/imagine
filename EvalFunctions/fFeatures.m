function [dDataOut, sNames, sUnitFormat] = fFeatures(dImg, lMask)

% sName = 'Features';
sUnitFormat = '';

% GLCM parameters
num_img_values = 255; % splitting from min(dImg(:)) to max(dImg(:)) in NumLevels bins

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

% Determine connectivity and bounding box of this ROI:
[bounding_box,ROI_conn_3D_6,ROI_conn_3D_26,binary_dir_connectivity] = ...
    determine_ROI_3D_connectivity(lMask);


% Take the ROI sub-volume within the bounding box:
mask_vol_subvol = lMask(bounding_box(1,1):bounding_box(1,2) , ...
                           bounding_box(2,1):bounding_box(2,2) , ...
                           bounding_box(3,1):bounding_box(3,2) );      

                    
% Now take the image sub-volume that corresponds to this mask:
img_vol_subvol = dImg(bounding_box(1,1):bounding_box(1,2) , ...
                         bounding_box(2,1):bounding_box(2,2) , ...
                         bounding_box(3,1):bounding_box(3,2) );      
                 
%% Texture Metric Computation Loop
% Create a column-vector placeholder for the 42 texture metrics:
texture_metrics = zeros(42,1);

% Determine the number of voxels in the ROI. This is used to compute the
% histogram-based probabilities and also in the Size-Zone metrics
% computations:
num_ROI_voxels = length(find(mask_vol_subvol));

%%% Discretize the image volume to the desired number of graytones. The
%%% PORTS functions require the image voxel values to be {1,2,3,...,N}. 

% Find the min and max within only the ROI:
img_min = min(img_vol_subvol(mask_vol_subvol)); 
img_max = max(img_vol_subvol(mask_vol_subvol)); 


% Rescale to image volume to [0,N]:
img_vol_subvol = num_img_values .* (img_vol_subvol - img_min)/(img_max - img_min) ;

% Discretize and add 1 to get values {1,2,...,N+1}:
img_vol_subvol = floor(img_vol_subvol) + 1;

% The max value is currently one higher than it should be (N+1), so put 
% those voxels at the max value:
img_vol_subvol(img_vol_subvol==num_img_values+1) = num_img_values;

%%%%%
%%%%% Histogram-based computations:
%%%%%

% Compute the histogram of the ROI and probability of each voxel value:
vox_val_hist = zeros(num_img_values,1);
for this_vox_value = 1:num_img_values
    vox_val_hist(this_vox_value) = length(find((img_vol_subvol == this_vox_value) & (mask_vol_subvol == 1) ));
end

% Compute the relative probabilities from the histogram:
vox_val_probs = vox_val_hist / num_ROI_voxels;


% Compute the histogram_based metrics:
texture_metrics(1:6) = compute_histogram_metrics(vox_val_probs,num_img_values);

%%%%%
%%%%% GTDSM (Co-occurance) Matrix calculations:
%%%%%

% Create the Gray-Tone-Spatial-Dependence-Matrix (GTSDM):
GTSDM = compute_3D_GTSDM(mask_vol_subvol,img_vol_subvol,binary_dir_connectivity,num_img_values);

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

% Create the Neighborhood-Gray-Tone-Difference-Matrix(NGTDM):
[NGTDM,vox_occurances_NGD26] = compute_3D_NGTDM(mask_vol_subvol,img_vol_subvol,binary_dir_connectivity,num_img_values);


% Compute NGTDM metrics:
texture_metrics(27:31) = compute_NGTDM_metrics(NGTDM,num_img_values,vox_occurances_NGD26);

%%%%%
%%%%% Zone Size matrix and Metrics:
%%%%%

% Create the Zone Size Matrix:
GLZSM = compute_GLZSM(mask_vol_subvol,img_vol_subvol,num_img_values);

% Compute the Zone Size Metrics:
texture_metrics(32:42) = compute_zone_size_metrics(GLZSM,num_ROI_voxels);


% fractal dimension
yMin = find(sum(lMask,2),1,'first'); yMax = find(sum(lMask,2),1,'last');
xMin = find(sum(lMask,1),1,'first'); xMax = find(sum(lMask,1),1,'last');
dImgCropped = NaN * ones(size(dImg));
% dImgCropped = zeros(size(dImg));
dImgCropped(lMask) = dImg(lMask);
dImgCropped = dImgCropped(yMin:yMax,xMin:xMax);
dFeatFrac = fFractal(dImgCropped);

sNames = cat(1,metric_names,{'(43) fractal BC'; '(44) fractal MBC'; '(45) fractal TPSA'}).';
dDataOut = [texture_metrics.',dFeatFrac];


function [out] = GLCM_Features(glcm)
% 
% GLCM_Features Computes a subset of GLCM features in a vectorized fashion.
%
% See the code by by Avinash Uppuluri for references on how each of the
% features was computed (see file with ID 22354 in MathWork's File
% Exchange).
%
% Input:
%   glcm - Ng x Ng x Ndir matrix (Ng - number of gray levels, Ndir - number
%       of directions for which GLCMs were computed); assumed to be
%       symmetric
%
% Output:
%   out - a structure containing values of Haralick's features in the
%       respective fields
%
% -- Features computed --
% 01. Contrast: matlab/[1,2]                    (out.contr) [f4]
% 02. Correlation: [1,2]                        (out.corrp) [f6]
% 03. Energy (ASM): matlab / [1,2]              (out.energ) [f1]
% 04. Entropy: [2]                              (out.entro) [f2]
% 05. Homogeneity (Inv. Diff. Moment): [2]      (out.homop) [f7]
% 06. Sum of squares: Variance [1]              (out.sosvh) [f12]
% 07. Sum average [1]                           (out.savgh) [f13]
% 08. Sum variance [1]                          (out.svarh) [f14]
% 09. Sum entropy [1]                           (out.senth) [f15]
% 10. Difference variance [1]                   (out.dvarh) [f16]
% 11. Difference entropy [1]                    (out.denth) [f17]
% 12. Information measure of correlation1 [1]   (out.inf1h) [f18]
% 13. Informaiton measure of correlation2 [1]   (out.inf2h) [f19]
% 14. Autocorrelation                           (out.acorr)
% 15. Cluster prominence                        (out.clp)
% 16. Cluster shade                             (out.cls)
% 17. Dissimilarity                             (out.dissim)
% 18. Inverse difference                        (out.invd)
% 19. Inverse difference normalized             (out.invdn)
% 20. Inverse difference moment normalized      (out.idmn)
% 21. Maximum probability                       (out.maxp)
%
% TODO: 
%   The "maximal correlation coefficient" was not calculated due to
%   computational instability 
%   http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%
% Author: Pawel Kleczek (pawel.kleczek@agh.edu.pl)
% Last modified: 2016-06-28

% Modifications/Additions: Thomas Kuestner (thomas.kuestner@iss.uni-stuttgart.de)


if ((nargin > 2) || (nargin == 0))
   error('Too many or too few input arguments. Enter GLCM and pairs.');
else
   if ((size(glcm,1) <= 1) || (size(glcm,2) <= 1))
       error('The GLCM should be a 2-D or 3-D matrix.');
    elseif ( size(glcm,1) ~= size(glcm,2) )
       error('Each GLCM should be square with NumLevels rows and NumLevels cols');
    end    
end


format long e

Ng = size(glcm,1);

size_glcm_1 = size(glcm,1);
size_glcm_2 = size(glcm,2);
size_glcm_3 = size(glcm,3);

glcm_mean = zeros(size_glcm_3,1);
% glcm_var  = zeros(size_glcm_3,1);

% checked p_x p_y p_xplusy p_xminusy
p_x = zeros(size_glcm_1,size_glcm_3); % Ng x #glcms[1]  
p_y = zeros(size_glcm_2,size_glcm_3); % Ng x #glcms[1]
p_xminusy = zeros(size_glcm_1,1,size_glcm_3); %[1]


[Mj, Mi] = meshgrid(1:size_glcm_1,1:size_glcm_2);
Mi3d = repmat(Mi, [1 1 size_glcm_3]);
Mj3d = repmat(Mj, [1 1 size_glcm_3]);

T3d = repmat(abs(Mi - Mj) .^ 2, [1 1 size_glcm_3]);
contr = sum(sum(T3d .* glcm, 2), 1);

% 01. Contrast (contr)
out.contr = permute(contr, [2 3 1]);

glcm_sum = permute(sum(sum(glcm, 2) ,1), [2 3 1]);

for k = 1:size_glcm_3 % number glcms
    glcm(:,:,k) = glcm(:,:,k)./glcm_sum(k); % Normalize each glcm
    glcm_mean(k) = mean2(glcm(:,:,k)); % compute mean after norm
end

% Compute glcm_var
% n = size_glcm_1*size_glcm_2;
% mean3d = repmat(reshape(glcm_mean, [1 1 size_glcm_3]), [size_glcm_1 size_glcm_2 1]);
% d23d = (glcm - mean3d).^2;
% s = 1/(n-1) * sum(sum(d23d,2),1);
% glcm_var = permute(s, [2 3 1]);
    
% 03. ASM (energ)
t = glcm .^ 2;
energ3d = sum(sum(t,2),1);
out.energ = permute(energ3d, [2 3 1]);

% 06. Sum of squares: Variance (sosvh)
uX2 = sum(sum(Mi3d .* glcm));
uX2_3d = repmat(uX2, [size_glcm_1 size_glcm_2 1]);

t = glcm .* (Mi3d - uX2_3d) .^ 2;
sosvh3d = sum(sum(t,2),1);
out.sosvh = permute(sosvh3d, [2 3 1]);

% 04. Entropy (entro)
t = -glcm .* log(glcm + eps);
entro3d = sum(sum(t,2),1);
out.entro = permute(entro3d, [2 3 1]);

% 05. Homogeneity (homop)
t = glcm ./ repmat(1 + (Mi - Mj) .^ 2, [1 1 size_glcm_3]);
homop3d = sum(sum(t,2),1);
out.homop = permute(homop3d, [2 3 1]);


% Compute p_x and p_y
for k = 1:size_glcm_3
    glcm_k = glcm(:,:,k);
    p_x(:,k) = sum(glcm_k, 2);
    p_y(:,k) = sum(glcm_k, 1);
end

% seq1 = 2:2*size_glcm_1;
% seq2 = 0:(size_glcm_1-1);

% Compute p_xplusy and p_xminusy
% for i = 1:size_glcm_1
%     for j = 1:size_glcm_2
%         NOTE: No need to check this condition - i+j ALWAYS falls in the
%         range of 2:2*size_glcm_1, as size_glcm_1 == size_glcm_2
%         if any(seq1 == i + j)
%             p_xplusy((i+j)-1,1,:) = p_xplusy((i+j)-1,1,:) + glcm(i,j,:);
%         end
        
%         NOTE: No need to check this condition - |i-j| ALWAYS falls in the
%         range of 0:(size_glcm_1-1), as size_glcm_1 == size_glcm_2
%         if any(seq2 == abs(i-j))
%             p_xminusy((abs(i-j))+1,1,:) = p_xminusy((abs(i-j))+1,1,:) + glcm(i,j,:);
%         end
%     end
% end
% p_xplusy = permute(p_xplusy, [1 3 2]);
% p_xminusy = permute(p_xminusy, [1 3 2]);

% -----
dim1 = size_glcm_1;
dim1m1 = dim1 - 1;

indexes = cell(2 * dim1 - 1,1);

% for k = 1:(dim1*2 - 1)
%     indexes{k} = k + (0:(k-1)) * dim1m1;
% end

indexes{1} = 1;
for k = 2:dim1
    indexes{k} = [indexes{k-1} + 1, k + (k-1) * dim1m1];
end
for k = (dim1+1):size(indexes,1)
    indexes{k} = indexes{k-1}(2:end) + 1;
end

for k = 1:size_glcm_3
    glcmk = glcm(:,:,k);
    for m = 1:length(indexes)
        p_xplusy(m,k) = sum(glcmk(indexes{m}));
    end
end

% dim1 = size_glcm_1;
% dim1m1 = dim1 - 1;
% 
% indexes = zeros(2 * dim1 - 1,dim1);
% indexes(1) = 1;
% for k = 2:dim1
%     indexes(k,1:k) = [indexes(k-1, 1:(k-1)) + 1, k + (k-1) * dim1m1];
% end
% for k = (dim1+1):size(indexes,1)
%     indexes(k,1:(size(indexes,1)-k+1)) = indexes(k-1,2:size(indexes,1)-k+2) + 1;
% end
% 
% indexes(indexes == 0) = 1;
% 
% modifiers = [(dim1 - 1):-1:0 1:(dim1-1)]';
% 
% p_xplusy = zeros(2 * dim1 - 1, size_glcm_3);
% for k = 1:size_glcm_3
%     glcmk = glcm(:,:,k);
%     p_xplusy(:,k) = sum(glcmk(indexes),2) - modifiers * glcm(1,1,k);
% end

p_xplusy = permute(p_xplusy, [1 3 2]);

% --

dim1p1 = dim1 + 1;

indexesL = cell(dim1,1);
indexesU = cell(dim1,1);

indexesL{1} = 1:dim1p1:dim1^2;
indexesU{1} = 1:dim1p1:dim1^2;

for k = 2:dim1
    indexesL{k} = indexesL{k-1}(1:end-1) + 1;
    indexesU{k} = indexesU{k-1}(2:end) - 1;
end
indexesU{1} = [];
indexes = cellfun(@(c1, c2) [c1 c2], indexesL, indexesU, 'UniformOutput',false);

for k = (dim1+1):size(indexes,1)
    indexes{k} = indexes{k-1}(2:end) + 1;
end

for k = 1:size_glcm_3
    glcmk = glcm(:,:,k);
    for m = 1:length(indexes)
        p_xminusy(m,k) = sum(glcmk(indexes{m}));
    end
end

% -----

p_xplusy2d = permute(p_xplusy, [1 3 2]);

% 07. Sum average (savgh)
out.savgh = sum(repmat((2:(2*size_glcm_1))', [1 size_glcm_3]) .* p_xplusy2d);
% 09. Sum entropy (senth)
out.senth = -sum(p_xplusy2d .* log(p_xplusy2d + eps));

% 08. Sum variance with the help of sum entropy (svarh)
t = repmat((0:(2*size_glcm_1-2))', [1 size_glcm_3]) - repmat(out.senth, [size(p_xplusy,1) 1]);
out.svarh = sum(t.^2 .* p_xplusy2d);


% 11. Difference entropy (denth)
out.denth = -sum(p_xminusy .* log(p_xminusy + eps));
out.denth = squeeze(out.denth)';

% 10. difference variance (dvarh)
p_xminusy2d = permute(p_xminusy, [1 3 2]);
% t = repmat(((0:(size_glcm_1-1)) .^ 2)', [1 size_glcm_3]);
% out.dvarh = sum(t .* p_xminusy2d);
%
% (use formula implemented in WND-CHARM - below)
ssq = sum(repmat((1:Ng)'.^2, [1 k]) .* p_xminusy2d);
s = sum((repmat((1:Ng)', [1 k]) .* p_xminusy2d) .^2);
out.dvarh = ssq - s;

    
hx = -sum(p_x .* log(p_x + eps));
hy = -sum(p_y .* log(p_y + eps));

hxy = out.entro;

p_x3d = reshape(p_x, [size_glcm_1 1 size_glcm_3]);
p_xM = repmat(p_x3d, [1 size_glcm_2 1]);

p_y3d = reshape(p_y, [1 size_glcm_2 size_glcm_3]);
p_yM = repmat(p_y3d, [size_glcm_1 1 1]);

p_xyM = p_xM .* p_yM;
p_xylogM = log(p_xyM + eps);

t = -(glcm .* p_xylogM);
hxy13d = sum(sum(t,2),1);
hxy1 = squeeze(hxy13d)';

t = -(p_xyM .* p_xylogM);
hxy23d = sum(sum(t,2),1);
hxy2 = squeeze(hxy23d)';

% 12. Information measure of correlation1 (inf1h)
out.inf1h = ( hxy - hxy1 ) ./ ( max([hx;hy]) );
% 13. Information measure of correlation2 (inf2h)
out.inf2h = ( 1 - exp( -2*( hxy2 - hxy ) ) ) .^ 0.5;


% Compute u_x
Ux3d = Mi3d .* glcm;
u_x3d = sum(sum(Ux3d,2),1);
u_x = squeeze(u_x3d)';

% Compute u_y
Uy3d = Mj3d .* glcm;
u_y3d = sum(sum(Uy3d,2),1);
u_y = squeeze(u_y3d)';

% Compute s_x
u_xM = repmat(u_x3d, [size_glcm_1 size_glcm_2]);
t = (repmat(Mi, [1 1 size_glcm_3]) - u_xM) .^ 2 .* glcm;
s_x3d = sum(sum(t,2),1);
s_x = squeeze(s_x3d) .^ 0.5;

% Compute s_y
u_yM = repmat(u_y3d, [size_glcm_1 size_glcm_2]);
t = (repmat(Mj, [1 1 size_glcm_3]) - u_yM) .^ 2 .* glcm;
s_y3d = sum(sum(t,2),1);
s_y = squeeze(s_y3d) .^ 0.5;

t = repmat(Mi .* Mj, [1 1 size_glcm_3]) .* glcm;
% 14. Autocorrelation
out.acorr = t;
corp3d = sum(sum(t,2),1);
corp = squeeze(corp3d);

% Compute corm
% t = (Mi3d - u_xM) .* (Mj3d - u_yM) .* glcm;
% corm3d = sum(sum(t,2),1);
% corm = permute(corm3d, [2 3 1])';

% 02. Correlation (corrp)
out.corrp = (corp' - u_x .* u_y) ./ (s_x .* s_y)';

% 16. Cluster shade (cls)
out.cls = (Mi3d + Mj3d - Ux3d - Uy3d).^3 .* glcm;

% 15. Cluster prominence (clp)
out.clp = out.cls .* (Mi3d + Mj3d - Ux3d - Uy3d);

% 17. Dissimilarity (dissim)
out.dissim = abs(Mi3d - Mj3d) .* glcm;

% 18. Inverse difference (invd)
out.invd = glcm./(1+abs(Mi3d - Mj3d));

% 19. Inverse difference normalized (invdn)
out.invdn = glcm./(1 + (abs(Mi3d - Mj3d)./Ng));

% 20. Inverse difference moment normalized (idmn) 
out.idmn = glcm./(1 + ((Mi3d - Mj3d)./Ng).^2);

% 21. Maximum probability 
out.maxp = max(max(glcm,[],1),[],2);


function featFrac = fFractal(I)
% The largest size of the box
allWidth = 2.^[1:10];
lInd = find(allWidth - max(size(I)) > 0,1, 'first');    
width = allWidth(lInd);
p = log(width)/log(2);   

RescaledI = imresize(I,[width width]);

% Allocation of the number of box size
n = zeros(1,p+1); 
counter=0;
counter_dbc = 0;
counter_tpsa =0;
step = width./2.^(1:p);
testim =[];

%------------------- 2D boxcount ---------------------%
for n = 1:1:size(step,2)
    stepnum = step(1,n);
    for i = 1: stepnum:width 
        for j = 1: stepnum:width
            
            % Get the Grid in each level
            testim = RescaledI(i:i +stepnum-1,j:j +stepnum-1);
            
            % Differential(Modified) Box Counting
            MaxGrayLevel = max(max(testim));
            MinGrayLevel = min(min(testim));
            GridCont = MaxGrayLevel-MinGrayLevel+1;
            counter_dbc = counter_dbc + GridCont;
            % Differential(Modified) Box Counting (MBC)
            
            %Triangular Prism Surface Area (TPSA)
            a = testim(1,1);
            b = testim(1,end);
            c = testim(end,1);
            d = testim(end,end);
            e = (a+b+c+d)/4;
            
            w = sqrt(((b-a)^2) + (stepnum^2));
            x = sqrt(((c-b)^2) + (stepnum^2));
            y = sqrt(((d-c)^2) + (stepnum^2));
            z = sqrt(((a-d)^2) + (stepnum^2));
            
            o = sqrt(((a-e)^2) + (0.5*stepnum^2));
            p2 = sqrt(((b-e)^2) + (0.5*stepnum^2));
            q = sqrt(((c-e)^2) + (0.5*stepnum^2));
            t = sqrt(((d-e)^2) + (0.5*stepnum^2));
            
            % Using Herons Formula
            
            sa = (w+p2+o)/2;
            sb = (x+p2+q)/2;
            sc = (y+q+t)/2;
            sd = (z+o+t)/2;
            
            % Areas of Traiangle
            
            S_ABE = sqrt((sa)*(sa-w)*(sa-p2)*(sa-o));
            S_BCE = sqrt((sb)*(sb-x)*(sb-p2)*(sb-q));
            S_CDE = sqrt((sc)*(sc-q)*(sc-t)*(sc-y));
            S_DAE = sqrt((sd)*(sd-z)*(sd-o)*(sd-t));
            SurfaceArea = S_ABE + S_BCE + S_CDE + S_DAE;
            counter_tpsa = counter_tpsa + SurfaceArea;
            %Triangular Prism Surface Area

            
            % Basic Box Counting (BC)
            if (size(find(testim~=0),1)~=0)
                counter = counter+1;
            end	
            % Basic Box Counting
            
        end
    end
    N_mbc (1,n) = counter_dbc;
    N_tpsa (1,n) = counter_tpsa;
    N_b(1,n) = counter;
    counter = 0;
    counter_dbc = 0;
    counter_tpsa = 0;
    n=n+1;
end

% Box-Count values
N_b; 
N_mbc; 
N_tpsa;


% Resolusion
r0 = (2.^(p:-1:1));

% Dimension of BC
x0 = log(r0);
y0 = log(N_b);
FDMat_BC = (y0)./(x0);
D0 = polyfit(x0, y0, 1);
FD_BC = D0(1);

% Dimension of MBC
x1 = log(r0);
y1 = log(N_mbc);
FDMat_MBC = (y1)./(x1);
D1 = polyfit(x1, y1, 1);
FD_MBC = D1(1);

% Dimension of MBC
x2 = log(r0);
y2 = log(N_tpsa);
FDMat_TPSA = (y2)./(x2);
D2 = polyfit(x2, y2, 1);
FD_TPSA = 2 - D2(1);

featFrac = [FD_BC , FD_MBC, FD_TPSA]; %, FDMat_BC, FDMat_MBC, FDMat_TPSA];




