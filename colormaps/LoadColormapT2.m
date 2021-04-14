function dColormap = LoadColormapT2(iNBins)
%OPTIMALCOLORS Example custom colormap for use with imagine
%  DCOLORMAP = OPTIMALCOLOR(INBINS) returns a double colormap array of size
%  (INBINS, 3). Use this template to implement you own custom colormaps.
%  Imagine will interpret all m-files in this folder as potential colormap-
%  generating functions an list them using the filename.

load('ColormapT2MRF.mat')
% -------------------------------------------------------------------------
% Process input
if ~nargin, iNBins = 256; end
iNBins = uint16(iNBins);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create look-up tables (pairs of x- and y-vectors) for the three colors
dYRed = ColormapT2(:,1);
dXRed = linspace(1,256,length(dYRed));

dYGrn = ColormapT2(:,2);
dXGrn = linspace(1,256,length(dYGrn));

dYBlu = ColormapT2(:,3);
dXBlu = linspace(1,256,length(dYBlu));
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Interpolate and concatenate vectors to the final colormap
dRedInt = interp1(dXRed, dYRed, linspace(1, 255, iNBins)');
dGrnInt = interp1(dXGrn, dYGrn, linspace(1, 255, iNBins)');
dBluInt = interp1(dXBlu, dYBlu, linspace(1, 255, iNBins)');

dColormap = [dRedInt, dGrnInt, dBluInt];
% -------------------------------------------------------------------------

% =========================================================================
% *** END OF FUNCTION OptimalColor
% =========================================================================