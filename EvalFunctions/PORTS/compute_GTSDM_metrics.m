% Function to compute the 14 metrics from Haralick 1973 for an input GTSDM
%
% The input GTSDM is an NxN matrix, where N is the number of graytones in
% the image. This corresponds to the GTSDM for a single direction.
%
% The output is a 19x1 column vector, M, of the metrics taken from papers
% Haralick 1973 and Soh 1999.
%
% The first 14 entries in the output are from Haralick (1973):
%
% (1) Angular second moment (called "Energy" in Soh 1999)
% (2) Contrast
% (3) Correlation 
% (4) Sum of squares variance
% (5) Inverse Difference moment (called "Homogeneity" in Soh 1999)
% (6) Sum average:
% (7) Sum variance
% (8) Sum Entropy
% (9) Entropy
% (10) Difference Variance
% (11) Difference Entropy
% (12) Information Correlation 1
% (13) Information Correlation 2
% (14) Maximal Correlation Coefficient *** NOT COMPUTED -- ALWAYS ZERO ***
% 
% The next five entries in the output are from Soh (1999):
%
% (15) Autocorrelation
% (16) Dissimilarity
% (17) Cluster Shade
% (18) Cluster Prominence
% (19) Maximum Probability
%
% The next entries are from Clausi (2002):
%
% (20) Inverse Difference (Not to be confused with (5)
%
% NOTE: The definition of "Correlation" differs between Haralick 1973 and
% Clausi 2002.
%
% If called with no inputs, the ouput is a cell array of the names of each
% metric.
%
%
% USAGE:
% 
% metrics_vector = compute_GTSDM_metrics_3(input_GTSDM)




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







function metrics_vect = compute_GTSDM_metrics(GTSDM)

%%
if nargin == 0
    metrics_vect = {'GTSDM - Angular Second Moment' ; ...
                    'GTSDM - Contrast' ; ...
                    'GTSDM - Correlation ' ; ...
                    'GTSDM - Sum of squares variance' ; ...
                    'GTSDM - Inverse Difference moment' ; ... 
                    'GTSDM - Sum average' ; ...
                    'GTSDM - Sum variance' ; ...
                    'GTSDM - Sum Entropy' ; ...
                    'GTSDM - Entropy' ; ...
                    'GTSDM - Difference Variance' ; ...
                    'GTSDM - Difference Entropy' ; ...
                    'GTSDM - Information Correlation 1' ; ...
                    'GTSDM - Information Correlation 2' ; ...
                    'GTSDM - Maximal Correlation Coefficient (=0)' ; ... 
                    'GTSDM - Autocorrelation' ; ...
                    'GTSDM - Dissimilarity' ; ...
                    'GTSDM - Cluster Shade' ; ...
                    'GTSDM - Cluster Prominence' ; ...
                    'GTSDM - Maximum Probability' ; ...
                    'GTSDM - Inverse Difference' };
    return
end

%%

% This is the output vector of computed metrics:
metrics_vect = zeros(20,1);



%% Pre-compute a few things according to the notation in Haralick 1973:

% The number of graytones:
N_g = size(GTSDM,1);

% Normalized GTSDM:
p = GTSDM./sum(GTSDM(:));

% Marginal distributions:
p_x = sum(p,2);
p_y = sum(p,1)';

% p_{x+y} (xpy for syntax). The paper has indices {2,3,...2N_g}, we wil use
% the converntion the p_{x_y}(1) = 0 and just never use it:
p_xpy = zeros(2*N_g,1);
for this_row = 1:N_g
    for this_col = 1:N_g
        p_xpy(this_row+this_col) = p_xpy(this_row+this_col) + p(this_row,this_col);
    end
end

% p_{x-y} (p_xmy for syntax). The paper has indices from {0,1,...,N_g-1}.
% We will shift by 1 with indices {1,...,N_g} and compensate where needed. 
p_xmy = zeros(N_g,1);
for this_row = 1:N_g
    for this_col = 1:N_g
        p_xmy(abs(this_row-this_col)+1) = p_xmy(abs(this_row-this_col)+1) + p(this_row,this_col);
    end
end


% Not in the paper, but useful for programming:
[ndr,ndc] = ndgrid(1:N_g,1:N_g);

%% Compute metrics (not in the same order as the paper)

% Sum Entropy:
SE = -sum(p_xpy(p_xpy>0) .* log(p_xpy(p_xpy>0)));


% Entropy (NOTE: this is also HXY used later):
HXY = -sum(p(p>0) .* log(p(p>0)) );

% Needed for later:
pp_xy = p_x * p_y';

HXY1 = -sum( p(pp_xy > 0) .* log( pp_xy(pp_xy > 0)) );
HXY2 = -sum( pp_xy(pp_xy > 0) .* log( pp_xy(pp_xy > 0)) );

HX = -sum( p_x(p_x>0) .* log(p_x(p_x>0)) );
HY = -sum( p_y(p_y>0) .* log(p_y(p_y>0)) );



% (1) Angular second moment
metrics_vect(1) = sum( p(:).^2 );


% (2) Contrast (for some reason, the paper does not explicitly state p_xmy
% here):
metrics_vect(2) = sum( ((0:(N_g-1))' .^2) .*  p_xmy  );


% (3) Correlation (there is mathematical ambiguity in the nature of the sum as
% stated in the paper ; this version has the means subtracted after the sum is 
% taken, which is the proper method for computation):
mu_x = sum( (1:N_g)' .* p_x );
mu_y = sum( (1:N_g)' .* p_y );
sg_x = sqrt( sum( ( ((1:N_g)' - mu_x).^2 ) .* p_x ) );
sg_y = sqrt( sum( ( ((1:N_g)' - mu_y).^2 ) .* p_y ) );

if (sg_x*sg_y) == 0
    metrics_vect(3) = Inf;
else
    metrics_vect(3) = ( sum(ndr(:) .* ndc(:) .* p(:) ) - (mu_x*mu_y)  ) ./ (sg_x*sg_y);
end


% (4) Sum of squares variance (NOTE: \mu is not defined in the paper, we will
% take it to describe the mean of the normalized GTSDM):
metrics_vect(4) = sum( (( ndr(:) - mean(p(:)) ) .^2) .* p(:) );


% (5) Inverse Difference moment
metrics_vect(5) = sum( ( 1 ./ (1 + ((ndr(:)-ndc(:)).^2) )  ) .* p(:) );


% (6) Sum average
metrics_vect(6) = sum( (1:(2*N_g))' .* p_xpy(:) ); % NOTE: p_xpy(1) = 0 , so adds nothing.


% (7) Sum variance
metrics_vect(7) = sum( (((1:(2*N_g))' - metrics_vect(6)) .^2) .* p_xpy(:));


% (8) Sum Entropy (computed above)
metrics_vect(8) = SE;


% (9) Entropy (computed above)
metrics_vect(9) = HXY;

% (10) Difference Variance
mu_xmy = sum( (0:(N_g-1))' .*  p_xmy );
metrics_vect(10) = sum( (((0:(N_g-1))' - mu_xmy) .^2) .*  p_xmy  );



% (11) Difference Entropy
metrics_vect(11) = -sum( p_xmy(p_xmy>0) .* log(p_xmy(p_xmy>0)) );


% (12) and (13) Information Correlations
if (max(HX,HY)== 0)
    metrics_vect(12) = Inf;
else
    metrics_vect(12) = (HXY - HXY1) / max(HX,HY);
end

metrics_vect(13) = sqrt(1-exp(-2*(HXY2-HXY)) );


% (14) Maximal Correlation Coefficient
%%% I don't think we use it, so I'll only code it up if needed.


%%%%%
%%%%% The following are from Soh (1999)
%%%%%

% (15) Autocorrelation
metrics_vect(15) = sum( (ndr(:) .* ndc(:)) .* p(:) );


% (16) Dissimilarity
metrics_vect(16) = sum( abs(ndr(:) - ndc(:)) .* p(:) );


% (17) Cluster Shade
metrics_vect(17) = sum( (ndr(:) + ndc(:) - mu_x - mu_y) .^3 .* p(:) );


% (18) Cluster Prominence
metrics_vect(18) = sum( (ndr(:) + ndc(:) - mu_x - mu_y) .^4 .* p(:) );


% (19) Maximum Probability
metrics_vect(19) = max( p(:) );


%%%%%
%%%%% The following are from Clausi (2002)
%%%%%

% (20) Inverse Difference:
metrics_vect(20) = sum( ( 1 ./ (1 + abs( ndr(:)-ndc(:) ) )  ) .* p(:) );




%%% Final END statement:
end



