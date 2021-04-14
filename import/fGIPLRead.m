function [dImg, dDim] = fGIPLRead(sFilename)

fid = fopen(sFilename, 'rb', 'ieee-be');
if fid < 0
    error('Could not open the file ''%s''!', sFilename);
end

% -------------------------------------------------------------------------
% Read the relevant hearder data
iSize      = fread(fid,  4, 'ushort')'; % 8
iType      = fread(fid,  1, 'ushort');  % 10
dDim       = fread(fid,  4, 'float')';  % 26
fseek(fid, 210, 'cof'); % Skip stuff
dIntercept = fread(fid,  1, 'float');   % 240
dSlope     = fread(fid,  1, 'float');   % 244
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Find start of volume data
iNumEl = prod(iSize);
switch iType
    case 1,             dBytesPerVoxel = 1./8;
    case {7, 8},        dBytesPerVoxel = 1;
    case {15, 16},      dBytesPerVoxel = 2;
    case {31, 32, 64},  dBytesPerVoxel = 4;
    case 65,            dBytesPerVoxel = 8;
end
fseek(fid, -iNumEl.*dBytesPerVoxel, 'eof');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Read volume data (convert all data to double)
switch iType
    case  1, dImg = fread(fid, iNumEl, 'bit1');
    case  7, dImg = fread(fid, iNumEl, 'int8');
    case  8, dImg = fread(fid, iNumEl, 'uchar');
    case 15, dImg = fread(fid, iNumEl, 'short');
    case 16, dImg = fread(fid, iNumEl, 'ushort');
    case 31, dImg = fread(fid, iNumEl, 'uint');
    case 32, dImg = fread(fid, iNumEl, 'int');
    case 64, dImg = fread(fid, iNumEl, 'float');
    case 65, dImg = fread(fid, iNumEl, 'double');
end
fclose(fid);
% -------------------------------------------------------------------------


dImg = dImg.*dSlope + dIntercept;
dImg = reshape(dImg, iSize);