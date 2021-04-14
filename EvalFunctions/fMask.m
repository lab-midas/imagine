function [ sName, sUnitString ] = fMask( lMaskIn, iSlice, sEvalFilename, iPos )
%FMASK 

sName = 'Mask';
sUnitString = '';
sEvalFilename = [sEvalFilename(1:end-3),'mat'];

if(iPos < 0) % file does not exist
    lMask = {lMaskIn, iSlice};
    save(sEvalFilename, 'lMask', '-v7.3');
else
    mf = matfile(sEvalFilename, 'Writable', true);
    mf.lMask(end+1,:) = {lMaskIn,iSlice};
end


end

