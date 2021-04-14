function [data, sName, sUnitFormat] = fQuality( )
%FMASK 

sName = 'QualityScore';
sUnitFormat = '';

lDone = false;
iCnt = 1;
sDefault = {'', '', ''};

while(~lDone)
    data = inputdlg({'Image 1 (1-best, 3-worst)', 'Image 2 (1-best, 3-worst)', 'Image 3 (1-best, 3-worst)'}, 'Likert-Scale', [1 10; 1 10; 1 10], sDefault);
    lEmpty = cellfun(@(x) isempty(x), data);
    [data{lEmpty}] = deal('0');
    data = cellfun(@(x) str2double(x), data);
    iCnt = iCnt + 1;
    if(iCnt > 5 || all(data >= 1 & data <= 3))
        lDone = true;
    else
        fprintf('imagine::fQuality(): Incorrect input\n');
        sDefault = num2cell(num2str(data)).';
    end
end

end

