function dColormap = GreenYellowRed(iNBins)
%LOGGRAY Example custom colormap for use with imagine
%  DCOLORMAP = LOGGRAY(INBINS) returns a double colormap array of size
%  (INBINS, 3). Use this template to implement you own custom colormaps.
%  Imagine will interpret all m-files in this folder as potential colormap-
%  generating functions an list them using the filename.

% -------------------------------------------------------------------------
% Process input
if ~nargin, iNBins = 256; end
depthA = round(double(iNBins)/2);
depthB = double(iNBins) - depthA;

dColormap = cat(1, colorgradient([0 0.5 0], [1 1 0], depthA), colorgradient([1 1 0], [1 0 0], depthB));
% -------------------------------------------------------------------------

function grad = colorgradient(c1,c2,depth)
    % COLORGRADIENT allows you to generate a gradient between 2 given colors,
    % that can be used as colormap in your figures.
    %
    % USAGE:
    %
    % [grad,im]=getGradient(c1,c2,depth)
    %
    % INPUT:
    % - c1: color vector given as Intensity or RGB color. Initial value.
    % - c2: same as c1. This is the final value of the gradient.
    % - depth: number of colors or elements of the gradient.
    %
    % OUTPUT:
    % - grad: a matrix of depth*3 elements containing colormap (or gradient).
    % - im: a depth*20*3 RGB image that can be used to display the result.
    %
    % EXAMPLES:
    % grad=colorGradient([1 0 0],[0.5 0.8 1],128);
    % surf(peaks)
    % colormap(grad);
    %
    % --------------------
    % [grad,im]=colorGradient([1 0 0],[0.5 0.8 1],128);
    % image(im); %display an image with the color gradient.

    % Copyright 2011. Jose Maria Garcia-Valdecasas Bernal
    % v:1.0 22 May 2011. Initial release.

    %determine increment step for each color channel.
    dr=(c2(1)-c1(1))/(depth-1);
    dg=(c2(2)-c1(2))/(depth-1);
    db=(c2(3)-c1(3))/(depth-1);

    %initialize gradient matrix.
    grad=zeros(depth,3);
    %initialize matrix for each color. Needed for the image. Size 20*depth.
    r=zeros(20,depth);
    g=zeros(20,depth);
    b=zeros(20,depth);
    %for each color step, increase/reduce the value of Intensity data.
    for j=1:depth
        grad(j,1)=c1(1)+dr*(j-1);
        grad(j,2)=c1(2)+dg*(j-1);
        grad(j,3)=c1(3)+db*(j-1);
        r(:,j)=grad(j,1);
        g(:,j)=grad(j,2);
        b(:,j)=grad(j,3);
    end

    % dColormap = grad;
    %merge R G B matrix and obtain our image.
    % im=cat(3,r,g,b);
end
end


% =========================================================================
% *** END OF FUNCTION GreenRed
% =========================================================================