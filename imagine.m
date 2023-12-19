function hF = imagine(varargin)
% IMAGINE IMAGe visualization, analysis and evaluation engINE
%
%   IMAGINE starts the IMAGINE user interface without initial data
%
%   IMAGINE(DATA) Starts the IMAGINE user interface with one (DATA is 3D)
%   or multiple panels (DATA is 4D).
%
%   IMAGINE(DATA, PROPERTY1, VALUE1, ...)) Starts the IMAGINE user
%   interface with data DATA plus supplying some additional information
%   about the dataset in the usual property/value pair format. Possible
%   combinations are:
%       PROPERTY        VALUE
%       'Name'          String: A name for the dataset
%       'Voxelsize'     [3x1] or [1x3] double: The voxel size of the first
%                       three dimensions of DATA.
%       'Units'         String: The physical unit of the pixels (e.g. 'mm')
%
%   IMAGINE(DATA1, DATA2, ...) Starts the IMAGINE user interface with
%   multiple panels, where each input can be either a 3D- or 4D-array. Each
%   dataset can be defined more detailedly with the properties above. 
%
%
% Examples:
%
% 1. >> load mri % Gives variable D
%    >> imagine(squeeze(D)); % squeeze because D is in rgb format
%
% 2. >> load mri % Gives variable D
%    >> imagine(squeeze(D), 'Name', 'Head T1', 'Voxelsize', [1 1 2.7]);
% This syntax gives a more realistic aspect ration if you rotate the data.
%
% For more information about the IMAGINE functions refer to the user's
% guide file in the documentation folder supplied with the code.
%
% Copyright 2012-2015 Christian Wuerslin, University Hospital of TÃ¼bingen,
% Contact: christian.wuerslin@med.uni-tuebingen.de
%
% Extension 2014-2020 Thomas KÃ¼stner, University Hospital of TÃ¼bingen
% Contact: thomas.kuestner@med.uni-tuebingen.de

% =========================================================================
% Warp Zone! (using Cntl + D)
% -------------------------------------------------------------------------
% *** The callbacks ***
% fCloseGUI                 % On figure close
% fResizeFigure             % On figure resize
% fIconClick                % On clicking menubar or tool icons
% fWindowMouseHoverFcn      % Standard figure mouse move callback
% fWindowButtonDownFcn      % Figure mouse button down function
% fWindowMouseMoveFcn       % Figure mouse move function when button is pressed or ROI drawing active
% fWindowButtonUpFcn        % Figure mouse button up function: Starts most actions
% fKeyPressFcn              % Keyboard callback
% fContextFcn               % Context menu callback
% fSetWindow                % Callback of the colorbars
% 
% -------------------------------------------------------------------------
% *** IMAGINE Core ***
% fFillPanels
% fUpdateActivation
% fZoom
% fWindow
% fChangeImage
% fChangeNDim
% fEval
%
% -------------------------------------------------------------------------
% *** Lengthy subfunction ***
% fLoadFiles
% fParseInputs
% fAddImageToData
% fSaveToFiles
%
% -------------------------------------------------------------------------
% *** Helpers ***
% fCreatePanels
% fGetPanel
% fServesSizeCriterion
% fIsOn
% fGetNActiveVisibleSeries
% fGetNVisibleSeries
% fGetImg
% fGetData
% fPrintNumber
% fBackgroundImg
% fReplicate
%
% -------------------------------------------------------------------------
% *** GUIS ***
% fGridSelect
% fColormapSelect
% fSelectEvalFcns
% =========================================================================

% =========================================================================
% *** FUNCTION imagine
% ***
% *** Main GUI function. Creates the figure and all its contents and
% *** registers the callbacks.
% ***
% =========================================================================

% versioning (Thomas Kuestner)
% v2.1: added 4D/5D support and through-time ROI analysis
% v2.2: added quiver plots
% v2.3: improved rotation of flows and minor bugfixes

% -------------------------------------------------------------------------
% Control the figure's appearance
SAp.sVERSION          = '2.3 - Belly Jeans';
SAp.sTITLE            = ['IMAGINE ',SAp.sVERSION];% Title of the figure
SAp.iICONSIZE         = 24;                     % Size if the icons
SAp.iICONPADDING      = SAp.iICONSIZE/2;        % Padding between icons
SAp.iMENUBARHEIGHT    = SAp.iICONSIZE*2;        % Height of the menubar (top)
SAp.iTOOLBARWIDTH     = SAp.iICONSIZE*2;        % Width of the toolbar (left)
SAp.iTITLEBARHEIGHT   = 24;                     % Height of the titles (above each image)
SAp.iCOLORBARHEIGHT   = 12;                     % Height of the colorbar
SAp.iCOLORBARPADDING  = 60;                     % The space on the left and right of the colorbar for the min/max values
SAp.iEVALBARHEIGHT    = 16;                     % Height of the evaluation bar
SAp.iDISABLED_SCALE   = 0.3;                    % Brightness of disabled buttons (decrease to make darker)
SAp.iINACTIVE_SCALE   = 0.6;                    % Brightness of inactive buttons (toggle buttons and radio groups)
SAp.dBGCOLOR          = [0.15 0.25 0.35];       % Color scheme
SAp.dEmptyImg         = 0;                      % The background image (is calculated in fResizeFigure);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set some paths.
SPref.sMFILEPATH    = fileparts(mfilename('fullpath'));                 % This is the path of this m-file
SPref.sICONPATH     = [SPref.sMFILEPATH, filesep, 'icons', filesep];    % That's where the icons are
configFolder = getenv('IMAGINE_CONFIG_PATH');
if isempty(configFolder) configFolder = SPref.sMFILEPATH, end;
SPref.sSaveFilename = [configFolder, filesep, 'imagineSave.mat'];   % A .mat-file to save the GUI settings
addpath([SPref.sMFILEPATH, filesep, 'EvalFunctions'], ...
        [SPref.sMFILEPATH, filesep, 'colormaps'], ...
        [SPref.sMFILEPATH, filesep, 'import'], ...
        [SPref.sMFILEPATH, filesep, 'tools']);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Define some preferences
S = load('mylines.mat');
SPref.dCOLORMAP             = S.mylines;% The color scheme of the overlays and lines
SPref.cMarkers              = {'x', '+', 'o', '*', '.', 's', 'd', '^', 'v', '<', '>', 'p', 'h'}; % a list of markers used in ROI overlay plotting
SPref.dWINDOWSENSITIVITY    = 0.02;     % Defines mouse sensitivity for windowing operation
SPref.dZOOMSENSITIVITY      = 0.02;     % Defines mouse sensitivity for zooming operation
SPref.dROTATION_THRESHOLD   = 50;       % Defines the number of pixels the cursor has to move to rotate an image
SPref.dLWRADIUS             = 200;      % The radius in which the path maps are calculated in the livewire algorithm
SPref.lGERMANEXPORT         = false;    % Not a beer! Determines whether the data is exported with a period or a comma as decimal point
SPref.iQUIVERFACTOR         = 8;        % Defines quiver factor distance [px] for flow visualization
SPref.iQUIVERSTRENGTH       = 100;      % Defines quiver factor strength [%] for flow visualization
SPref.iQUIVERCOLOR          = [1 1 0];  % Defines quiver color
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% This is the definition of the menubar. If a radiobutton-like
% functionality is to implemented, the GroupIndex parameter of all
% icons within the group has to be set to the same positive integer
% value. Normal Buttons have group index -1, toggel switches have group
% index 0. The toolbar has the GroupIndex 255.
SIcons = struct( ...
    'Name',        {'folder_open',                 'doc_import',          'save', 'doc_delete', 'print', 'exchange',          'grid', 'colormap',        'flow',         'link',          'link1',     'reset',       'phase',                          'max',                          'min',         'record',                    'stop',               'rewind',           'clock',               'line1',     'cursor_arrow', 'rotate',               'line',            'roi',                      'lw',                               'rg',                    'ic',        'tag'}, ...
    'Spacer',      {            0,                            0,               0,            0,       0,          1,               0,          0,             0,              0,                0,           1,             0,                              0,                              1,                0,                         0,                      0,                 0,                     0,                  0,        0,                    0,                0,                         0,                                  0,                       0,            0}, ...
    'GroupIndex',  {           -1,                           -1,              -1,           -1,      -1,         -1,              -1,         -1,            -1,              0,                0,          -1,             1,                              1,                              1,               -1,                        -1,                     -1,                 0,                     0,                255,      255,                  255,              255,                       255,                                255,                     255,          255}, ...
    'Enabled',     {            1,                            1,               0,            0,       1,          0,               1,          1,             1,              1,                1,           1,             1,                              1,                              1,                1,                         0,                      1,                 1,                     1,                  1,        1,                    1,                1,                         1,                                  1,                       1,            1}, ...
    'Active',      {            1,                            1,               1,            1,       1,          1,               1,          1,             1,              1,                0,           1,             0,                              0,                              0,                1,                         1,                      1,                 0,                     1,                  1,        0,                    0,                0,                         0,                                  0,                       0,            0}, ...
    'Accelerator', {          'o',                          'i',             's',     'delete',     'p',        'x',              '',         '',            '',            'l',               '',         '0',            '',                             '',                             '',              'r',                       'r',                    'z',               'c',                   'w',                'm',      'r',                  'l',              'o',                       'w',                                'g',                     'i',          't'}, ...
    'Modifier',    {       'Cntl',                       'Cntl',          'Cntl',           '',      '',     'Cntl',              '',         '',            '',         'Cntl',               '',      'Cntl',            '',                             '',                             '',           'Cntl',                     'Alt',                 'Cntl',            'Cntl',                'Cntl',                 '',       '',                   '',               '',                        '',                                 '',                      '',           ''}, ...
    'Tooltip',     {'Open Files' , 'Import Workspace Variables', 'Save To Files',     'Delete', 'Print', 'Exchange', 'Change Layout', 'Colormap', 'Change Flow', 'Link Actions', 'Link Windowing','Reset View', 'Phase Image', 'Maximum Intensity Projection', 'Minimum Intensity Projection', 'Log Evaluation', 'Stop Logging Evaluation', 'Undo Last Evaluation', 'Eval Timeseries', 'Show Line/ROI Plots', 'Move/Zoom/Window', 'Rotate', 'Profile Evaluation', 'ROI Evaluation', 'Livewire ROI Evaluation', 'Region Growing Volume Evaluation', 'Isocontour Evaluation', 'Properties'});
% -------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Reset the GUI's state variable
SState.iLastSeries     = 0;
SState.iStartSeries    = 1;
SState.sTool           = 'cursor_arrow';
SState.sPath           = [SPref.sMFILEPATH, filesep];
SState.csEvalLineFcns  = {};
SState.csEvalROIFcns   = {};
SState.csEvalVolFcns   = {};
SState.sEvalFilename   = [];
SState.iROIState       = 0;     % The ROI state machine
SState.dROILineX       = [];
SState.dROILineY       = [];
SState.iPanels         = [0, 0];
SState.lShowColorbar   = true;
SState.lShowEvalbar    = true;
SState.dColormapBack   = gray(256);
SState.dColormapMask   = S.mylines;
SState.dMaskOpacity    = 0.5;
SState.sDrawMode       = 'mag';
SState.dTolerance      = 1.0;
SState.hEvalFigure     = 0.1;
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Create some globals
SData                  = [];    % A struct for hoding the data (image data + visualization parameters)
SImg                   = [];    % A struct for the image component handles
SLines                 = [];    % A struct for the line component handles
SMouse                 = [];    % A Struct to hold parameters of the mouse operations
SPanels                = [];    % A Struct to hold the panel data
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Read the preferences from the save file
iPosition = [100 100 1000 600];
if exist(SPref.sSaveFilename, 'file')
    SSaveVar = [];
    load(SPref.sSaveFilename);
    SState.sPath            = SSaveVar.sPath;
    SState.csEvalLineFcns   = SSaveVar.csEvalLineFcns;
    SState.csEvalROIFcns    = SSaveVar.csEvalROIFcns;
    SState.csEvalVolFcns    = SSaveVar.csEvalVolFcns;
    iPosition               = SSaveVar.iPosition;
    SPref.lGERMANEXPORT     = SSaveVar.lGermanExport;
    clear SSaveVar; % <- no one needs you anymore! :((
else
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % First-time call: Do some setup
    sAns = questdlg('Do you want to use periods (anglo-american) or commas (german) as decimal separator in the exported .csv spreadsheet files? This is important for a smooth Excel import.', 'IMAGINE First-Time Setup', 'Stick to the point', 'Use se commas', 'Stick to the point');
    SPref.lGERMANEXPORT = strcmp(sAns, 'Use se commas');
    fCompileMex;
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Make sure the figure fits on the screen
iScreenSize = get(0, 'ScreenSize');
if (iPosition(1) + iPosition(3) > iScreenSize(3)) || ...
   (iPosition(2) + iPosition(4) > iScreenSize(4))
    iPosition(1:2) = 50;
    iPosition(3:4) = iScreenSize(3:4) - 100;
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create the figure. Mouse scroll wheel is supported since Version 7.4 (I think).
hF = figure(...
    'BusyAction'           , 'cancel', ...
    'Interruptible'        , 'off', ...
    'Position'             , iPosition, ...
    'Units'                , 'pixels', ...
    'Color'                , SAp.dBGCOLOR, ...
    'ResizeFcn'            , @fResizeFigure, ...
    'DockControls'         , 'on', ...
    'MenuBar'              , 'none', ...
    'Name'                 , SAp.sTITLE, ...
    'NumberTitle'          , 'off', ...
    'KeyPressFcn'          , @fKeyPressFcn, ...
    'CloseRequestFcn'      , @fCloseGUI, ...
    'WindowButtonDownFcn'  , @fWindowButtonDownFcn, ...
    'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
try
    set(hF, 'WindowScrollWheelFcn' , @fChangeImage);
catch
    warning('IMAGINE: No scroll wheel functionality!');
end
colormap(gray(256));

try % Try to apply a nice icon
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jframe = get(hF, 'javaframe');
    jIcon = javax.swing.ImageIcon([SPref.sMFILEPATH, filesep, 'icons', filesep, 'icon.png']);
    pause(0.001);
    jframe.setFigureIcon(jIcon);
    clear jframe jIcon
catch
    warning('IMAGINE: Could not apply a nifty icon to the figure :(');
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Crate context menu for the region growing
hContextMenu = uicontextmenu;
uimenu(hContextMenu, 'Label', 'Tolerance +50%', 'Callback', @fContextFcn);
uimenu(hContextMenu, 'Label', 'Tolerance +10%', 'Callback', @fContextFcn);
uimenu(hContextMenu, 'Label', 'Tolerance -10%', 'Callback', @fContextFcn);
uimenu(hContextMenu, 'Label', 'Tolerance -50%', 'Callback', @fContextFcn);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create the menubar and the toolbar including their components
SPanels.hMenu  = uipanel('Parent', hF, 'BackgroundColor', 'k', 'BorderWidth', 0, 'Units', 'pixels');
SPanels.hTools = uipanel('Parent', hF, 'BackgroundColor', 'k', 'BorderWidth', 0, 'Units', 'pixels');

SAxes.hIcons = zeros(length(SIcons), 1);
SImg .hIcons = zeros(length(SIcons), 1);

iStartPos = SAp.iTOOLBARWIDTH - SAp.iICONSIZE;
for iI = 1:length(SIcons)
    if SIcons(iI).GroupIndex ~= 255, iStartPos = iStartPos + SAp.iICONPADDING + SAp.iICONSIZE; end
    
    dImage = double(imread([SPref.sICONPATH, SIcons(iI).Name, '.png'])); % icon file name (.png) has to be equal to icon name
    if size(dImage, 3) == 1, dImage = repmat(dImage, [1 1 3]); end
    SIcons(iI).dImg = dImage./255;
    
    if SIcons(iI).GroupIndex == 255, hParent = SPanels.hTools; else hParent = SPanels.hMenu; end
    SAxes.hIcons(iI) = axes('Parent', hParent, 'Units', 'pixels', 'Position'  , [iStartPos SAp.iICONPADDING SAp.iICONSIZE SAp.iICONSIZE]); %#ok<LAXES>
    SImg.hIcons(iI) = image(SIcons(iI).dImg, 'Parent', SAxes.hIcons(iI),'ButtonDownFcn' , @fIconClick);
    if SIcons(iI).Spacer, iStartPos = iStartPos + SAp.iICONSIZE; end
end
axis(SAxes.hIcons, 'off');
SState.dIconEnd = iStartPos + SAp.iICONPADDING + SAp.iICONSIZE;

STexts.hStatus = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'FontName'              , 'Helvetica Neue', ...
    'FontWeight'            , 'light', ...
    'Parent'                , SPanels.hMenu, ...
    'FontUnits'             , 'normalized', ...
    'FontSize'              , 0.7, ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'HorizontalAlignment'   , 'right', ...
    'Units'                 , 'pixels');

clear iStartPos hParent iI dImage
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Parse Inputs and determine and create the initial amount of panels
if ~isempty(varargin), fParseInputs(varargin); end
if ~prod(SState.iPanels), SState.iPanels = [1 1]; end
fCreatePanels;
clear varargin; % <- no one needs you anymore! :((
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Update the figure components
fUpdateActivation(); % Acitvate/deactivate some buttons according to the gui state
fResizeFigure(hF, []); % Call the resize function to allign all the gui elements
set(hF, 'UserData', @fGetData);
drawnow expose
% -------------------------------------------------------------------------
% The 'end' of the IMAGINE main function. The real end is, of course, after
% all the nested functions. Using the nested functions, shared varaiables
% (the variables of the IMAGINE function) can be used which makes the usage
% of the 'guidata' commands obsolete.
% =========================================================================



    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fCloseGUI (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Closes the figure and saves the settings
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseGUI(hObject, eventdata) %#ok<*INUSD> eventdata is repeatedly unused
        % -----------------------------------------------------------------
        % Save the settings
        SSaveVar.sPath          = SState.sPath;
        SSaveVar.csEvalLineFcns = SState.csEvalLineFcns;
        SSaveVar.csEvalROIFcns  = SState.csEvalROIFcns;
        SSaveVar.csEvalVolFcns  = SState.csEvalVolFcns;
        SSaveVar.iPosition      = get(hObject, 'Position');
        SSaveVar.lGermanExport  = SPref.lGERMANEXPORT;
        try
            save(SPref.sSaveFilename, 'SSaveVar');
        catch
            warning('Could not save the settings! Is the IMAGINE folder protected?');
        end
        % -----------------------------------------------------------------
        
        delete(hObject); % Bye-bye figure
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCloseGUI
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fResizeFigure (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Re-arranges all the GUI elements after a figure resize
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fResizeFigure(hObject, eventdata)
        % -----------------------------------------------------------------
        % The resize callback is called very early, therefore we have to check
        % if the GUI elements were already created and return if not
        if ~isfield(SPanels, 'hImgFrame'), return, end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get figure dimensions
        dFigureSize   = get(hF, 'Position');
        dFigureWidth  = dFigureSize(3);
        dFigureHeight = dFigureSize(4);
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Arrange the panels and all their contents
        for iM = 1:SState.iPanels(1)
            for iN = 1:SState.iPanels(2)
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Determine the position of the panel
                iLinInd = (iM - 1).*SState.iPanels(2) + iN;
                dWidth  = round((dFigureWidth  - SAp.iTOOLBARWIDTH) / SState.iPanels(2)) - 1;
                dHeight = round((dFigureHeight - SAp.iMENUBARHEIGHT) / SState.iPanels(1)) - 1;
                dXStart =                 (iN - 1).*(dWidth  + 1) + 2 + SAp.iTOOLBARWIDTH;
                dYStart = (SState.iPanels(1) - iM).*(dHeight + 1) + 2;
                if iN == SState.iPanels(2), dWidth  = dFigureWidth                       - dXStart; end
                if iM == 1                , dHeight = dFigureHeight - SAp.iMENUBARHEIGHT - dYStart; end
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Arrange the panels
                set(SPanels.hImgFrame(iLinInd),  'Position', [dXStart, dYStart, dWidth, dHeight]);
                dImgYStart = 1 + SState.lShowEvalbar.*SAp.iEVALBARHEIGHT;
                dImgHeight = dHeight - SAp.iTITLEBARHEIGHT - SState.lShowColorbar.*SAp.iCOLORBARHEIGHT - SState.lShowEvalbar.*SAp.iEVALBARHEIGHT;
                set(SPanels.hImg(iLinInd), 'Position', [1, dImgYStart, dWidth, dImgHeight]);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                set(STexts.hImg1(iLinInd), 'Position', [5,  dHeight - SAp.iTITLEBARHEIGHT + 4, dWidth - 85, SAp.iTITLEBARHEIGHT - 4]);
                set(STexts.hImg2(iLinInd), 'Position', [dWidth - 160, dHeight - SAp.iTITLEBARHEIGHT + 4, 155, SAp.iTITLEBARHEIGHT - 4]); % -80
                
                set(SAxes.hColorbar(iLinInd), 'Position', [SAp.iCOLORBARPADDING, dHeight - SAp.iCOLORBARHEIGHT - SAp.iTITLEBARHEIGHT + 4, max([dWidth - 2*SAp.iCOLORBARPADDING, 1]), SAp.iCOLORBARHEIGHT - 3]);
                set(STexts.hColorbarMin(iLinInd), 'Position', [5, dHeight - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT + 3, SAp.iCOLORBARPADDING - 10, 12]);
                set(STexts.hColorbarMax(iLinInd), 'Position', [dWidth - SAp.iCOLORBARPADDING + 5, dHeight - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT + 3, SAp.iCOLORBARPADDING - 10, 12]);
                
                set(STexts.hEval, 'Position', [5, 2, dWidth - 100, SAp.iEVALBARHEIGHT - 1]);
                set(STexts.hVal,  'Position', [dWidth - 305, 2, 300, SAp.iEVALBARHEIGHT - 1]);
            end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Arrange the menubar
        dTextWidth = max([dFigureWidth - SState.dIconEnd - 10, 1]);
        set(SPanels.hMenu, 'Position', [1, dFigureHeight - SAp.iMENUBARHEIGHT + 1, dFigureWidth, SAp.iMENUBARHEIGHT]);
        set(STexts.hStatus, 'Position', [SState.dIconEnd + 5, 10, dTextWidth, 28]);
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Arrange the toolbar
        set(SPanels.hTools, 'Position', [1, 1, SAp.iTOOLBARWIDTH, dFigureHeight - SAp.iMENUBARHEIGHT]);
        iStartPos = dFigureHeight - SAp.iMENUBARHEIGHT - SAp.iICONPADDING - SAp.iICONSIZE;
        for i = 1:length(SIcons) % Unfortunately we have to rearrange all the icons to keep them on top :(
            if SIcons(i).GroupIndex ~= 255, continue, end
            
            set(SAxes.hIcons(i), 'Position', [SAp.iICONPADDING, iStartPos, SAp.iICONSIZE, SAp.iICONSIZE]);
            iStartPos = iStartPos - SAp.iICONSIZE - SAp.iICONPADDING;
        end
        % -----------------------------------------------------------------
        
        % -------------------------------------------------------------------------
        % Create a beatuiful image for the empty axes
        dWidth  = ceil((dFigureWidth  - SAp.iTOOLBARWIDTH) / SState.iPanels(2));
        dHeight = ceil((dFigureHeight - SAp.iMENUBARHEIGHT) / SState.iPanels(1)) - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT - SAp.iEVALBARHEIGHT;
        SAp.dEmptyImg = fBackgroundImg(dHeight, dWidth);
        % -------------------------------------------------------------------------
        
        fFillPanels;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fResizeFigure
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fIconClick (nested in imagine)
    % * * 
    % * * Common callback for all buttons in the menubar
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fIconClick(hObject, eventdata)
        % -----------------------------------------------------------------
        % Get the source's (pressed buttton) data and exit if disabled
        iInd = find(SImg.hIcons == hObject);
        if ~SIcons(iInd).Enabled, return, end;
        % -----------------------------------------------------------------
        
        sActivate = [];
        % -----------------------------------------------------------------
        % Distinguish the idfferent button types (normal, toggle, radio)
        switch SIcons(iInd).GroupIndex
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % NORMAL pushbuttons
            case -1

                switch(SIcons(iInd).Name)
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % LOAD new FILES using file dialog
                    case 'folder_open'
                        if strcmp(get(hF, 'SelectionType'), 'normal')
                            % Load Files
                            [csFilenames, sPath] = uigetfile( ...
                                {'*.*', 'All Files'; ...
                                '*.dcm; *.DCM; *.mat; *.MAT; *.jpg; *.jpeg; *.JPG; *.JPEG; *.tif; *.tiff; *.TIF; *.TIFF; *.gif; *.GIF; *.bmp; *.BMP; *.png; *.PNG; *.nii; *.NII; *.gipl; *.GIPL', 'All images'; ...
                                '*.mat; *.MAT', 'Matlab File (*.mat)'; ...
                                '*.jpg; *.jpeg; *.JPG; *.JPEG', 'JPEG-Image (*.jpg)'; ...
                                '*.tif; *.tiff; *.TIF; *.TIFF;', 'TIFF-Image (*.tif)'; ...
                                '*.gif; *.GIF', 'Gif-Image (*.gif)'; ...
                                '*.bmp; *.BMP', 'Bitmaps (*.bmp)'; ...
                                '*.png; *.PNG', 'Portable Network Graphics (*.png)'; ...
                                '*.dcm; *.DCM', 'DICOM Files (*.dcm)'; ...
                                '*.nii; *.NII', 'NifTy Files (*.nii)'; ...
                                '*.gipl; *.GIPL', 'Guys Image Processing Lab Files (*.gipl)'}, ...
                                'OpenLocation'  , SState.sPath, ...
                                'Multiselect'   , 'on');
                            if isnumeric(sPath), return, end;   % Dialog aborted
                        else
                            % Load a folder
                            sPath = uigetdir(SState.sPath);
                            if isnumeric(sPath), return, end;
                            
                            sPath = [sPath, filesep];
                            SFiles = dir(sPath);
                            SFiles = SFiles(~[SFiles.isdir]);
                            csFilenames = cell(length(SFiles), 1);
                            for i = 1:length(SFiles), csFilenames{i} = SFiles(i).name; end
                        end
                        
                        SState.sPath = sPath;
                        fLoadFiles(csFilenames);
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % IMPORT workspace (base) VARIABLE(S)
                    case 'doc_import'
                        csVars = fWSImport();
                        if isempty(csVars), return, end   % Dialog aborted
                        
                        for i = 1:length(csVars)
                            dVar = evalin('base', csVars{i});
                            fAddImageToData(dVar, csVars{i}, 'workspace');
                        end
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % SAVE panel data to file(s)
                    case 'save'
                        if strcmp(get(hF, 'SelectionType'), 'normal')
                            [sFilename, sPath] = uiputfile( ...
                                {'*.jpg', 'JPEG-Image (*.jpg)'; ...
                                '*.tif', 'TIFF-Image (*.tif)'; ...
                                '*.gif', 'Gif-Image (*.gif)'; ...
                                '*.bmp', 'Bitmaps (*.bmp)'; ...
                                '*.png', 'Portable Network Graphics (*.png)'}, ...
                                'Save selected series to files', ...
                                [SState.sPath, filesep, '%SeriesName%_%ImageNumber%']);
                            if isnumeric(sPath), return, end;   % Dialog aborted
                            
                            SState.sPath = sPath;
                            fSaveToFiles(sFilename, sPath);
                        else
                            [sFilename, sPath] = uiputfile( ...
                                {'*.jpg', 'JPEG-Image (*.jpg)'; ...
                                '*.tif', 'TIFF-Image (*.tif)'; ...
                                '*.gif', 'Gif-Image (*.gif)'; ...
                                '*.bmp', 'Bitmaps (*.bmp)'; ...
                                '*.png', 'Portable Network Graphics (*.png)'}, ...
                                'Save MASK of selected series to files', ...
                                [SState.sPath, filesep, '%SeriesName%_%ImageNumber%_Mask']);
                            if isnumeric(sPath), return, end;   % Dialog aborted
                            
                            SState.sPath = sPath;
                            fSaveMaskToFiles(sFilename, sPath);
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                    
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % SAVE panel data to file(s)
                    case 'print'
%                         if strcmp(get(hF, 'SelectionType'), 'normal')
                            [sFilename, sPath] = uiputfile( ...
                                {'*.tif', 'TIFF-Image (*.tif)'; ...
                                '*.gif', 'Gif-Image (*.gif)'; ...
                                '*.bmp', 'Bitmaps (*.bmp)'; ...
                                '*.jpg', 'JPEG-Image (*.jpg)'; ...
                                '*.png', 'Portable Network Graphics (*.png)'}, ...
                                'Save selected series to files', ...
                                [SState.sPath, filesep, '%SeriesName%_%ImageNumber%']);
                            if isnumeric(sPath), return, end;   % Dialog aborted
                            
                            SState.sPath = sPath;
                            fSaveToFiles(sFilename, sPath, true);
%                         else
%                             [sFilename, sPath] = uiputfile( ...
%                                 {'*.tif', 'TIFF-Image (*.tif)'; ...
%                                 '*.gif', 'Gif-Image (*.gif)'; ...
%                                 '*.bmp', 'Bitmaps (*.bmp)'; ...
%                                 '*.jpg', 'JPEG-Image (*.jpg)'; ...
%                                 '*.png', 'Portable Network Graphics (*.png)'}, ...
%                                 'Save MASK of selected series to files', ...
%                                 [SState.sPath, filesep, '%SeriesName%_%ImageNumber%_Mask']);
%                             if isnumeric(sPath), return, end;   % Dialog aborted
%                             
%                             SState.sPath = sPath;
%                             fSaveToFiles(sFilename, sPath, true, true);
%                         end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % DELETE DATA from structure
                    case 'doc_delete'
                        iSeriesInd = find([SData.lActive]); % Get indices of selected axes
                        iSeriesInd = iSeriesInd(iSeriesInd >= SState.iStartSeries);
                        SData(iSeriesInd) = []; % Delete the visible active data
                        fFillPanels();
                        fUpdateActivation(); % To make sure panels without data are not selected
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % EXCHANGE SERIES
                    case 'exchange'
                        iSeriesInd = find([SData.lActive]); % Get indices of selected axes
                        SData1 = SData(iSeriesInd(1));
                        SData(iSeriesInd(1)) = SData(iSeriesInd(2)); % Exchange the data
                        SData(iSeriesInd(2)) = SData1;
                        fFillPanels();
                        fUpdateActivation(); % To make sure panels without data are not selected
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Determine the NUMBER OF PANELS and their LAYOUT
                    case 'grid'
                        iPanels = fGridSelect(4, 4);
                        if ~sum(iPanels), return, end   % Dialog aborted
                        
                        SState.iPanels = iPanels;
                        fCreatePanels; % also updates the SState.iPanels
                        fFillPanels;
                        fUpdateActivation;
                        fResizeFigure(hF, []);
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Select the COLORMAP
                    case 'colormap'
                        dColormap = fColormapSelect(STexts.hStatus);
                        if ~isempty(dColormap)
                            SState.dColormapBack = dColormap;
                            fFillPanels;
                            colormap(dColormap);
                            set(SPanels.hImg, 'BackgroundColor', dColormap(1,:));
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Select the FLOW
                    case 'flow'
                        [SPref.iQUIVERFACTOR, SPref.iQUIVERSTRENGTH, SPref.iQUIVERCOLOR] = fFlowSelect(STexts.hStatus, SPref.iQUIVERFACTOR, SPref.iQUIVERSTRENGTH, SPref.iQUIVERCOLOR);
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % RESET the view (zoom/window/center)
                    case 'reset' % Reset the view properties of all data
                        for i = 1:length(SData)
                            SData(i).dZoomFactor = 1;
                            SData(i).dWindowCenter = mean(SData(i).dDynamicRange);
                            SData(i).dWindowWidth = SData(i).dDynamicRange(2) - SData(i).dDynamicRange(1);
                            SData(i).dDrawCenter = [0.5 0.5];
                        end
                        fFillPanels();
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % RECORD Start recording data
                    case 'record'
                        [sName, sPath] = uiputfile( ...
                            {'*.csv', 'Comma-separated File (*.csv)'}, ...
                            'Chose Logfile', SState.sPath);
                        if isnumeric(sPath)
                            SState.sEvalFilename = '';
                        else
                            SState.sEvalFilename = [sPath, sName];
                        end
                        SState.sPath = sPath;
                        fUpdateActivation;
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % STOP logging data
                    case 'stop'
                        SState.sEvalFilename = '';
                        fUpdateActivation;

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % REWIND last measurement
                    case 'rewind'
                        iPosDel = fGetEvalFilePos;
                        if iPosDel < 0
                            fprintf('File ''%s''does not exist yet or is write-protexted!\n', SState.sEvalFilename);
                            return
                        end
                        
                        if iPosDel == 0
                            fprintf('Log file ''%s'' is empty!\n', SState.sEvalFilename);
                            return
                        end
                        
                        fid = fopen(SState.sEvalFilename, 'r');
                        sLine = fgets(fid);
                        i = 1;
                        lLast = false;
                        while ischar(sLine)
                            csText{i} = sLine;
                            i = i + 1;
                            sLine = fgets(fid);
                            csPos = textscan(sLine, '"%d"');
                            if isempty(csPos{1})
                                iPos = 0;
                            else
                                iPos = csPos{1};
                            end
                            if iPos == iPosDel - 1, lLast = true; end
                            if iPos ~= iPosDel - 1 && lLast, break, end
                        end
                        fclose(fid);
                        iEnd = length(csText);
                        if iPosDel == 1, iEnd = 3; end
                        fid = fopen(SState.sEvalFilename, 'w');
                        for i = 1:iEnd
                            fprintf(fid, '%s', csText{i});
                        end
                        fprintf('Removed entry %d from ''%s''!\n', iPosDel, SState.sEvalFilename);
                        fclose(fid);
   
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    otherwise
                end
            % End of NORMAL buttons
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % TOGGLE buttons: Invert the state
            case 0
                SIcons(iInd).Active = ~SIcons(iInd).Active;
                fUpdateActivation();
                fFillPanels; % Because of link button
            % End of TOGGLE buttons
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The render-mode group
            case 1 % The render-mode group
                if ~strcmp(SState.sDrawMode, SIcons(iInd).Name)
                    SState.sDrawMode = SIcons(iInd).Name;
                    sActivate        = SIcons(iInd).Name;
                else
                    SState.sDrawMode = 'mag';
                end
                fFillPanels;

            case 255 % The toolbar
                % -   -   -   -   -   -   -   -   -   -   -   -   -
                % Right-click setup menus
                if strcmp(get(hF, 'SelectionType'), 'alt') && ~isfield(eventdata, 'Character')% Right click, open tool settings in neccessary
                    switch SIcons(iInd).Name
                        case 'line',
                            csFcns = fSelectEvalFcns(SState.csEvalLineFcns, [SPref.sMFILEPATH, filesep, 'EvalFunctions']);
                            if iscell(csFcns), SState.csEvalLineFcns = csFcns; end
                        case {'roi', 'lw'},
                            csFcns = fSelectEvalFcns(SState.csEvalROIFcns, [SPref.sMFILEPATH, filesep, 'EvalFunctions']);
                            if iscell(csFcns), SState.csEvalROIFcns = csFcns; end
                        case 'rg'
                            csFcns = fSelectEvalFcns(SState.csEvalVolFcns, [SPref.sMFILEPATH, filesep, 'EvalFunctions']);
                            if iscell(csFcns), SState.csEvalVolFcns = csFcns; end
                    end
                end
                % -   -   -   -   -   -   -   -   -   -   -   -   -

                % -   -   -   -   -   -   -   -   -   -   -   -   -
                if ~strcmp(SState.sTool, SIcons(iInd).Name) % Tool change
                    % Try to delete the lines of the ROI and line eval tools
                    if isfield(SLines, 'hEval')
                        try delete(SLines.hEval); end %#ok<TRYNC>
                        SLines = rmfield(SLines, 'hEval');
                    end
                    
                    % Set tool-specific context menus
                    switch SIcons(iInd).Name
                        case 'rg', set(SPanels.hImg, 'uicontextmenu', hContextMenu);
                        otherwise, set(SPanels.hImg, 'uicontextmenu', []);
                    end
                    
                    % Remove the masks, if a new eval tool is selected
                    switch SIcons(iInd).Name
                        case {'line', 'roi', 'lw', 'rg', 'ic'}
                            for i = 1:length(SData), SData(i).lMask = []; end
                            fFillPanels;
                    end

                    % -----------------------------------------------------------------
                    % Reset the ROI painting state machine and Mouse callbacks
                    SState.iROIState = 0;
                    set(gcf, 'WindowButtonDownFcn'  , @fWindowButtonDownFcn);
                    set(gcf, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                    set(gcf, 'WindowButtonUpFcn'    , '');
                    % -----------------------------------------------------------------
                end
                SState.sTool = SIcons(iInd).Name;
                sActivate    = SIcons(iInd).Name;
                % -   -   -   -   -   -   -   -   -   -   -   -   -

        end
        % -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

        % -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        % Common code for all radio groups
        if SIcons(iInd).GroupIndex > 0
            for i = 1:length(SIcons)
                    if SIcons(i).GroupIndex == SIcons(iInd).GroupIndex
                    SIcons(i).Active = strcmp(SIcons(i).Name, sActivate);
                end
            end
        end
        fUpdateActivation();
        % -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIconClick
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

      


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseHoverFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * The standard mouse move callback. Displays cursor coordinates and
    % * * intensity value of corresponding pixel.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowMouseHoverFcn(hObject, eventdata)
        if ~isfield(SPanels, 'hImgFrame'), return, end; % Return if called during GUI startup
        
        iAxisInd = fGetPanel();
        if iAxisInd
            % -------------------------------------------------------------
            % Cursor is over a panel -> show coordinates and intensity
            iPos = uint16(get(SAxes.hImg(iAxisInd), 'CurrentPoint')); % Get cursor poition in axis coordinate system
            
            for i = 1:length(SPanels.hImgFrame)
                iSeriesInd = SState.iStartSeries + i - 1;
                if iSeriesInd > length(SData), continue, end
                
                if iPos(1, 1) > 0 && iPos(1, 2) > 0 && iPos(1, 1) <= size(SData(iSeriesInd).dImg, 2) && iPos(1, 2) <= size(SData(iSeriesInd).dImg, 1)
                    switch SState.sDrawMode
                        case {'mag', 'phase'}
                            dImg = fGetImg(iSeriesInd);
                            dVal = dImg(iPos(1, 2), iPos(1, 1));
                        case 'max'
                            if isreal(SData(iSeriesInd).dImg)
                                dVal = max(SData(iSeriesInd).dImg(iPos(1, 2), iPos(1, 1), :), [], 3);
                            else
                                dVal = max(abs(SData(iSeriesInd).dImg(iPos(1, 2), iPos(1, 1), :)), [], 3);
                            end
                        case 'min'
                            if isreal(SData(iSeriesInd).dImg)
                                dVal = min(SData(iSeriesInd).dImg(iPos(1, 2), iPos(1, 1), :), [], 3);
                            else
                                dVal = min(abs(SData(iSeriesInd).dImg(iPos(1, 2), iPos(1, 1), :)), [], 3);
                            end
                    end
                    if(~isempty(SData(iSeriesInd).dFlow))
                        iFlow = fGetFlow(iSeriesInd, SData(iSeriesInd).iActiveImage, SData(iSeriesInd).iActiveND(1), SData(iSeriesInd).iActiveND(2));
                        dValFlow = iFlow(iPos(1, 2), iPos(1, 1),:);
                        if(size(dValFlow,3) < 3)
                            dValFlow = cat(3,dValFlow,0);
                        end
                    end
                    if i == iAxisInd
                        if(~isempty(SData(iSeriesInd).dFlow))
                            set(STexts.hStatus, 'String', sprintf('I(%u,%u) = %s, F(%s,%s,%s) = [%s,%s,%s]', iPos(1, 1), iPos(1, 2), fPrintNumber(dVal), SData(iSeriesInd).sOri(1:2), SData(iSeriesInd).sOri(3:4), SData(iSeriesInd).sOri(5:6), fPrintNumber(dValFlow(:,:,1)), fPrintNumber(dValFlow(:,:,2)), fPrintNumber(dValFlow(:,:,3)))); 
                        else
                            set(STexts.hStatus, 'String', sprintf('I(%u,%u) = %s', iPos(1, 1), iPos(1, 2), fPrintNumber(dVal))); 
                        end
                    end
                    if(~isempty(SData(iSeriesInd).dFlow))
                        set(STexts.hVal(i), 'String', sprintf('%s, (%s,%s,%s): [%s,%s,%s]', fPrintNumber(dVal), SData(iSeriesInd).sOri(1:2), SData(iSeriesInd).sOri(3:4), SData(iSeriesInd).sOri(5:6), fPrintNumber(dValFlow(:,:,1)), fPrintNumber(dValFlow(:,:,2)), fPrintNumber(dValFlow(:,:,3))));
                    else
                        set(STexts.hVal(i), 'String', sprintf('%s', fPrintNumber(dVal)));
                    end
                else
                    if i == iAxisInd, set(STexts.hStatus, 'String', ''); end
                    set(STexts.hVal(i), 'String', '');
                end
            end
            % -------------------------------------------------------------
        else
            % -------------------------------------------------------------
            % Cursor is not over a panel -> Check if tooltip has to be shown
            iCursorPos = get(hF, 'CurrentPoint');
            iInd = 0;
            for i = 1:length(SAxes.hIcons);
                dPos = get(SAxes.hIcons(i), 'Position');
                dParentPos = get(get(SAxes.hIcons(i), 'Parent'), 'Position');
                dPos(1:2) = dPos(1:2) + dParentPos(1:2);
                if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                        (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                    iInd = i;
                end
            end
            if iInd
                sText = SIcons(iInd).Tooltip;
                sAccelerator = SIcons(iInd).Accelerator;
                if ~isempty(SIcons(iInd).Modifier), sAccelerator = sprintf('%s+%s', SIcons(iInd).Modifier, SIcons(iInd).Accelerator); end
                if ~isempty(SIcons(iInd).Accelerator), sText = sprintf('%s [%s]', sText, sAccelerator); end
                set(STexts.hStatus, 'String', sText);
            else
                set(STexts.hStatus, 'String', '');
            end
            % -------------------------------------------------------------
        end

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseHoverFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonDownFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Starting callback for mouse button actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonDownFcn(hObject, eventdata)
        iAxisInd = fGetPanel();
        if ~iAxisInd, return, end % Exit if event didn't occurr in a panel

        % -----------------------------------------------------------------
        % Save starting parameters
        dPos = get(SAxes.hImg(iAxisInd), 'CurrentPoint');
        SMouse.iStartAxis       = iAxisInd;
        SMouse.iStartPos        = get(hObject, 'CurrentPoint');
        SMouse.dAxesStartPos    = [dPos(1, 1), dPos(1, 2)];
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Backup the display settings of all data
        SMouse.dDrawCenter   = reshape([SData.dDrawCenter], [2, length(SData)]);
        SMouse.dZoomFactor   = [SData.dZoomFactor];
        SMouse.dWindowCenter = [SData.dWindowCenter];
        SMouse.dWindowWidth  = [SData.dWindowWidth];
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Delete existing line objects, clear masks
        if isfield(SLines, 'hEval')
            try delete(SLines.hEval); end %#ok<TRYNC>
            SLines = rmfield(SLines, 'hEval');
        end
        switch SState.sTool
            case {'line', 'roi', 'lw', 'rg', 'ic'}
                for i = 1:length(SData), SData(i).lMask = []; end
                fFillPanels;
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Activate the callbacks for drag operations
            set(hObject, 'WindowButtonUpFcn',     @fWindowButtonUpFcn);
        set(hObject, 'WindowButtonMotionFcn', @fWindowMouseMoveFcn);
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonDownFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseMoveFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Callback for mouse movement while button is pressed.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =    
    function fWindowMouseMoveFcn(hObject, eventdata)
        iAxesInd = fGetPanel();
                
        % -----------------------------------------------------------------
        % Get some frequently used values
        lLinked   = fIsOn('link'); % Determines whether axes are linked
        iD        = get(hF, 'CurrentPoint') - SMouse.iStartPos; % Mouse distance travelled since button down
        dPanelPos = get(SPanels.hImg(SMouse.iStartAxis), 'Position');
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Tool-specific code
        switch SState.sTool

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The NORMAL CURSOR: select, move, zoom, window
            case 'cursor_arrow'
                switch get(hF, 'SelectionType')

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Normal, left mouse button -> MOVE operation
                    case 'normal' 
                        dD = double(iD)./dPanelPos(3:4); % Scale mouse movement to panel size (since DrawCenter is a relative value)
                        for i = 1:length(SData)
                            iAxisInd = i - SState.iStartSeries + 1;
                            if ~((lLinked) || (iAxisInd == SMouse.iStartAxis)), continue, end % Skip if axes not linked and current figure not active

                            dNewPos = SMouse.dDrawCenter(:, i)' + dD; % Calculate new draw center relative to saved one
                            SData(i).dDrawCenter = dNewPos; % Save DrawCenter data
                            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

                            dPos = get(SAxes.hImg(iAxisInd), 'Position');
                            set(SAxes.hImg(iAxisInd), 'Position', [dPanelPos(3)*(dNewPos(1)) - dPos(3)/2, dPanelPos(4)*(dNewPos(2)) - dPos(4)/2, dPos(3), dPos(4)]);
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Shift key or right mouse button -> ZOOM operation
                    case 'alt'
                        fZoom(iD, dPanelPos);

                    case 'extend' % Control key or middle mouse button -> WINDOW operation
                        fWindow(iD);
                end
            % end of the NORMAL CURSOR
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ROTATION tool
            case 'rotate'
                if ~any(abs(iD) > SPref.dROTATION_THRESHOLD), return, end   % Only proceed if action required

                iStartSeries = SMouse.iStartAxis + SState.iStartSeries - 1;
                for i = 1:length(SData)
                    if ~(lLinked || i == iStartSeries || SData(i).iGroupIndex == SData(iStartSeries).iGroupIndex), continue, end % Skip if axes not linked and current figure not active
                    
                    switch get(hObject, 'SelectionType')
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Normal, left mouse button -> volume rotation operation
                        case 'normal'
                            if iD(1) > SPref.dROTATION_THRESHOLD % Moved mouse to right
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 1));
                                iPermutation = [1 3 2]; iFlipdim = 2; iFlipdimFlow = 2; 
                                u = [0 1 0]; % around y axis
                                theta = -pi/2;
                                SData(i).sOri = SData(i).sOri([6 5 3 4 1 2]);
                            end
                            if iD(1) < -SPref.dROTATION_THRESHOLD % Moved mouse to left
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 2) - SMouse.dAxesStartPos(1, 1) + 1);
                                iPermutation = [1 3 2]; iFlipdim = 3; iFlipdimFlow = 3; 
                                u = [0 1 0]; % around y axis
                                theta = pi/2;
                                SData(i).sOri = SData(i).sOri([5 6 3 4 2 1]); 
                            end
                            if iD(2) > SPref.dROTATION_THRESHOLD % Moved mouse up
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 1) - SMouse.dAxesStartPos(1, 2) + 1);
                                iPermutation = [3 2 1]; iFlipdim = 3; iFlipdimFlow = 3; 
                                u = [1 0 0]; % around x axis
                                theta = -pi/2;
                                SData(i).sOri = SData(i).sOri([1 2 5 6 4 3]);
                            end
                            if iD(2) < -SPref.dROTATION_THRESHOLD % Moved mouse down
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 2));
                                iPermutation = [3 2 1]; iFlipdim = 1; iFlipdimFlow = 1; 
                                u = [1 0 0]; % around x axis
                                theta = pi/2;
                                SData(i).sOri = SData(i).sOri([1 2 6 5 3 4]);
                            end
                            
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Shift key or right mouse button -> rotate in-plane
                        case 'alt'
                            if any(iD > SPref.dROTATION_THRESHOLD) % 90° clock-wise
                                iPermutation = [2 1 3]; iFlipdim = 2; iFlipdimFlow = 2; lInPlane = true; 
                                u = [0 0 1]; % around z axis
                                theta = -pi/2;
%                                 SData(i).iRot(1:2) = [SData(i).iRot(2), mod(SData(i).iRot(2)-90,360)]; % [from, to]
                                SData(i).sOri = SData(i).sOri([4 3 1 2 5 6]); 
                            end
                            if any(iD < -SPref.dROTATION_THRESHOLD) % 90° counter clock-wise
                                iPermutation = [2 1 3]; iFlipdim = 1; iFlipdimFlow = 1; lInPlane = true; 
                                u = [0 0 1]; % around z axis
                                theta = pi/2;
%                                 SData(i).iRot(1:2) = [SData(i).iRot(2), mod(SData(i).iRot(2)+90,360)];
                                SData(i).sOri = SData(i).sOri([3 4 2 1 5 6]); 
                            end
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                    end
                    % Switch statement
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Apply the transformation
                    SData(i).dImg =  flipdim(permute(SData(i).dImg,  iPermutation), iFlipdim);
                    if(SData(i).lND)                          
                        SData(i).dImgAll = flipdim(permute(SData(i).dImgAll, [iPermutation, 4, 5]), iFlipdim);
                        if(ndims(SData(i).dImgAll) == 5)
                            iPermutationFlow = [iPermutation, 4, 5, 6];
                        else
                            iPermutationFlow = [iPermutation, 4, 5];
                        end
                    else
                        if(ndims(SData(i).dImg) == 3)
                            iPermutationFlow = [iPermutation, 4];
                        else
                            iPermutationFlow = [iPermutation(1:2), 3];
                        end
                    end
                    SData(i).lMask = flipdim(permute(SData(i).lMask, iPermutation), iFlipdim);

                    % check which dimension was swapped
                    iMult = ones(1,3);
                    if(strcmp(SData(i).sOri(1:2), 'LR') || strcmp(SData(i).sOri(1:2), 'FH') || strcmp(SData(i).sOri(1:2), 'PA'))
                        iMult(1) = -1;
                    end
                    if(strcmp(SData(i).sOri(3:4), 'LR') || strcmp(SData(i).sOri(3:4), 'FH') || strcmp(SData(i).sOri(3:4), 'PA'))
                        iMult(2) = -1;
                    end
                    if(strcmp(SData(i).sOri(5:6), 'LR') || strcmp(SData(i).sOri(5:6), 'FH') || strcmp(SData(i).sOri(5:6), 'PA'))
                        iMult(3) = -1;
                    end
%                     iMultPrev = SData(i).iMult;
%                     iMultTurn = iMult;
                       
                    if(~isempty(SData(i).dFlow))
                        SData(i).dFlow = flipdim(permute(SData(i).dFlow, iPermutationFlow), iFlipdimFlow);
                        
                        switch find(u)
                            case 1 % X axis rotation matrix ; u = i = [1 0 0]'
                                Rm = [1          0           0;
                                      0 cos(theta) -sin(theta);
                                      0 sin(theta)  cos(theta)];
                            case 2 % Y axis rotation matrix ; u = j = [0 1 0]'
                                Rm = [cos(theta)   0  -sin(theta);
                                      0            1           0;
                                      sin(theta)  0  cos(theta)];
                            case 3 % Z axis rotation matrix ; u = k = [0 0 1]'
                                Rm = [cos(theta) -sin(theta) 0;
                                      sin(theta)  cos(theta) 0;
                                      0           0          1];
                            otherwise % Any u axis rotation matrix

                                u = u/norm(u);

                                Rm = [u(1,1)^2+cos(theta)*(1-u(1,1)^2) (1-cos(theta))*u(1,1)*u(2,1)-u(3,1)*sin(theta) (1-cos(theta))*u(1,1)*u(3,1)+u(2,1)*sin(theta);
                                      (1-cos(theta))*u(1,1)*u(2,1)+u(3,1)*sin(theta) u(2,1)^2+cos(theta)*(1-u(2,1)^2) (1-cos(theta))*u(2,1)*u(3,1)-u(1,1)*sin(theta);
                                      (1-cos(theta))*u(1,1)*u(3,1)-u(2,1)*sin(theta) (1-cos(theta))*u(2,1)*u(3,1)+u(1,1)*sin(theta) u(3,1)^2+cos(theta)*(1-u(3,1)^2)];
                        end

                        SData(i).dFlow = shiftdim(SData(i).dFlow, ndims(SData(i).dFlow)-1);
                        if(exist('pagemtimes','builtin')) % >Matlab R2020b
                            SData(i).dFlow = pagemtimes(Rm, SData(i).dFlow);
                        else
                            SData(i).dFlow = mtimesx(Rm, SData(i).dFlow);
                        end
                        SData(i).dFlow = shiftdim(SData(i).dFlow, 1);
                        
%                         % deprecated
%                         iMinusDim = find(iMultTurn == -1);
%                         iMinusDimPrev = find(iMultPrev == -1);
%                         
%                         if(ndims(SData(i).dFlow) == 6)
%                             if(~isempty(iMinusDimPrev)), SData(i).dFlow(:,:,:,:,:,iMinusDimPrev) = -SData(i).dFlow(:,:,:,:,:,iMinusDimPrev); end;
%                             SData(i).dFlow = SData(i).dFlow(:,:,:,:,:,iPermutation);
%                             if(~isempty(iMinusDim)), SData(i).dFlow(:,:,:,:,:,iMinusDim) = -SData(i).dFlow(:,:,:,:,:,iMinusDim); end;
%                         elseif(ndims(SData(i).dFlow) == 5)
%                             if(~isempty(iMinusDimPrev)), SData(i).dFlow(:,:,:,:,iMinusDimPrev) = -SData(i).dFlow(:,:,:,:,iMinusDimPrev); end;
%                             SData(i).dFlow = SData(i).dFlow(:,:,:,:,iPermutation);
%                             if(~isempty(iMinusDim)), SData(i).dFlow(:,:,:,:,iMinusDim) = -SData(i).dFlow(:,:,:,:,iMinusDim); end;
%                         elseif(ndims(SData(i).dFlow) == 4)
%                             if(~isempty(iMinusDimPrev)), SData(i).dFlow(:,:,:,iMinusDimPrev) = -SData(i).dFlow(:,:,:,iMinusDimPrev); end;
%                             SData(i).dFlow = SData(i).dFlow(:,:,:,iPermutation);
%                             if(~isempty(iMinusDim)), SData(i).dFlow(:,:,:,iMinusDim) = -SData(i).dFlow(:,:,:,iMinusDim); end;
%                         else % 3
%                             if(~isempty(iMinusDimPrev)), SData(i).dFlow(:,:,iMinusDimPrev) = -SData(i).dFlow(:,:,iMinusDimPrev); end;
%                             SData(i).dFlow = SData(i).dFlow(:,:,iPermutation(1:2));
%                             if(~isempty(iMinusDim)), SData(i).dFlow(:,:,iMinusDim) = -SData(i).dFlow(:,:,iMinusDim); end;
%                         end
                    end
                    SData(i).iMult = iMult;
                    SData(i).dPixelSpacing = SData(i).dPixelSpacing(iPermutation);
                    set(hObject, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                    
                    % - - - - - - - - - - - - - - - - - - - - - - -
                    % Limit active image range to image dimensions
                    if SData(i).iActiveImage < 1, SData(i).iActiveImage = 1; end
                    if SData(i).iActiveImage > size(SData(i).dImg, 3), SData(i).iActiveImage = size(SData(i).dImg, 3); end
                end
                % Loop over the data
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                fFillPanels();
            % END of the rotate tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The LINE EVALUATION tool
            case 'line'
                if ~iAxesInd, return, end % Exit if event didn't occurr in a panel
                dPos = get(SAxes.hImg(iAxesInd), 'CurrentPoint');
                if ~isfield(SLines, 'hEval') % Make sure line object exists
                    for i = 1:length(SPanels.hImg)
                        if i + SState.iStartSeries - 1 > length(SData), continue, end
                        SLines.hEval(i) = line([SMouse.dAxesStartPos(1, 1), dPos(1, 1)], [SMouse.dAxesStartPos(1, 2), dPos(1, 2)], ...
                            'Parent'        , SAxes.hImg(i), ...
                            'Color'         , SPref.dCOLORMAP(i,:), ...
                            'LineStyle'     , '-');
                    end
                else
                    set(SLines.hEval, 'XData', [SMouse.dAxesStartPos(1, 1), dPos(1, 1)], 'YData', [SMouse.dAxesStartPos(1, 2), dPos(1, 2)]);
                end
                fWindowMouseHoverFcn(hF, []); % Update the position display by triggering the mouse hover callback
            % end of the LINE EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Handle special case of ROI drawing (update the lines), ellipse
            case 'roi'
                if ~iAxesInd || iAxesInd + SState.iStartSeries - 1 > length(SData), return, end
                
                switch SState.iROIState
                    
                    case 0 % No drawing -> Check if one should start an elliplse or rectangle
                        dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                        if sum((dPos(1, 1:2) - SMouse.dAxesStartPos).^2) > 4
                            for i = 1:length(SPanels.hImg)
                                if i + SState.iStartSeries - 1 > length(SData), continue, end
                                SLines.hEval(i) = line(dPos(1, 1), dPos(1, 2), ...
                                    'Parent'    , SAxes.hImg(i), ...
                                    'Color'     , SPref.dCOLORMAP(i,:),...
                                    'LineStyle' , '-');
                            end
                            switch(get(hF, 'SelectionType'))
                                case 'normal', SState.iROIState = 2; % -> Rectangle
                                case {'alt', 'extend'}, SState.iROIState = 3; % -> Ellipse
                            end
                        end
                        
                    case 1 % Polygon mode
                        dPos = get(SAxes.hImg(iAxesInd), 'CurrentPoint');
                        dROILineX = [SState.dROILineX; dPos(1, 1)]; % Draw a line to the cursor position
                        dROILineY = [SState.dROILineY; dPos(1, 2)];
                        set(SLines.hEval, 'XData', dROILineX, 'YData', dROILineY);

                    case 2 % Rectangle mode
                        dPos = get(SAxes.hImg(iAxesInd), 'CurrentPoint');
                        SState.dROILineX = [SMouse.dAxesStartPos(1); SMouse.dAxesStartPos(1); dPos(1, 1); dPos(1, 1); SMouse.dAxesStartPos(1)];
                        SState.dROILineY = [SMouse.dAxesStartPos(2); dPos(1, 2); dPos(1, 2); SMouse.dAxesStartPos(2); SMouse.dAxesStartPos(2)];
                        set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                        
                    case 3 % Ellipse mode
                        dPos = get(SAxes.hImg(iAxesInd), 'CurrentPoint');
                        dDX = dPos(1, 1) - SMouse.dAxesStartPos(1);
                        dDY = dPos(1, 2) - SMouse.dAxesStartPos(2);
                        if strcmp(get(hF, 'SelectionType'), 'extend')
                            dD = max(abs([dDX, dDY]));
                            dDX = sign(dDX).*dD;
                            dDY = sign(dDY).*dD;
                        end
                        dT = linspace(-pi, pi, 100)';
                        SState.dROILineX = SMouse.dAxesStartPos(1) + dDX./2.*(1 + cos(dT));
                        SState.dROILineY = SMouse.dAxesStartPos(2) + dDY./2.*(1 + sin(dT));
                        set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                end
                fWindowMouseHoverFcn(hF, []); % Update the position display by triggering the mouse hover callback
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Handle special case of LW drawing (update the lines)
            case 'lw'
                if iAxesInd == SMouse.iStartAxis 
                    if SState.iROIState == 1 && sum(abs(SState.iPX(:))) > 0 % ROI drawing in progress
                        dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                        [iXPath, iYPath] = fLiveWireGetPath(SState.iPX, SState.iPY, dPos(1, 1), dPos(1, 2));
                        if isempty(iXPath)
                            iXPath = dPos(1, 1);
                            iYPath = dPos(1, 2);
                        end
                        set(SLines.hEval, 'XData', [SState.dROILineX; double(iXPath(:))], ...
                                          'YData', [SState.dROILineY; double(iYPath(:))]);
                        drawnow expose
                    end
                end
                fWindowMouseHoverFcn(hF, []); % Update the position display by triggering the mouse hover callback
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            otherwise

        end
        % end of the TOOL switch statement
        % -----------------------------------------------------------------

        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonUpFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * End of mouse operations.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonUpFcn(hObject, eventdata)
        iAxisInd = fGetPanel();
        
        iCursorPos = get(hF, 'CurrentPoint');
        % -----------------------------------------------------------------
        % Stop the operation by disabling the corresponding callbacks
        set(hF, 'WindowButtonMotionFcn'    ,@fWindowMouseHoverFcn);
        set(hF, 'WindowButtonUpFcn'        ,'');
        set(STexts.hStatus, 'String', '');
        % -----------------------------------------------------------------
            
        % -----------------------------------------------------------------
        % Tool-specific code
        switch SState.sTool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The NORMAL CURSOR: select, move, zoom, window
            % In this function, only the select case has to be handled
            case 'cursor_arrow'
                if ~sum(abs(iCursorPos - SMouse.iStartPos)) % Proceed only if mouse was moved
                    
                    switch get(hF, 'SelectionType')
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % NORMAL selection: Select only current series
                        case 'normal'
                            iN = fGetNActiveVisibleSeries();
                            for iSeries = 1:length(SData)
                                if SMouse.iStartAxis + SState.iStartSeries - 1 == iSeries
                                    SData(iSeries).lActive = ~SData(iSeries).lActive || iN > 1;
                                else
                                    SData(iSeries).lActive = false;
                                end
                            end
                            SState.iLastSeries = SMouse.iStartAxis + SState.iStartSeries - 1; % The lastAxis is needed for the shift-click operation
                        % end of normal selection
                        % - - - - - - - - - - - - - - - - - - - - - - - - -

                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        %  Shift key or right mouse button: Select ALL axes
                        %  between last selected axis and current axis
                        case 'extend'
                            iSeriesInd = SMouse.iStartAxis + SState.iStartSeries - 1;
                            if sum([SData.lActive] == true) == 0
                                % If no panel active, only select the current axis
                                SData(iSeriesInd).lActive = true;
                                SState.iLastSeries = iSeriesInd;
                            else
                                if SState.iLastSeries ~= iSeriesInd
                                    iSortedInd = sort([SState.iLastSeries, iSeriesInd], 'ascend');
                                    for i = 1:length(SData)
                                        SData(i).lActive = (i >= iSortedInd(1)) && (i <= iSortedInd(2));
                                    end
                                end
                            end
                        % end of shift key/right mouse button
                        % - - - - - - - - - - - - - - - - - - - - - - - - -

                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Cntl key or middle mouse button: ADD/REMOVE axis
                        % from selection
                        case 'alt'
                            iSeriesInd = SMouse.iStartAxis + SState.iStartSeries - 1;
                            SData(iSeriesInd).lActive = ~SData(iSeriesInd).lActive;
                            SState.iLastSeries = iSeriesInd;
                        % end of alt/middle mouse buttton
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    end
                end
            % end of the NORMAL CURSOR
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The LINE EVALUATION tool
            case 'line'
                fEval(SState.csEvalLineFcns);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % End of the LINE EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ROI EVALUATION tool
            case 'roi'
                set(hF, 'WindowButtonMotionFcn', @fWindowMouseMoveFcn);
                set(hF, 'WindowButtonDownFcn', '');
                set(hF, 'WindowButtonUpFcn', @fWindowButtonUpFcn); % But keep the button up function
                                
                if iAxisInd && iAxisInd + SState.iStartSeries - 1 <= length(SData) % ROI drawing in progress
                    dPos = get(SAxes.hImg(iAxisInd), 'CurrentPoint');
                    
                    if SState.iROIState > 1 || any(strcmp({'extend', 'open'}, get(hF, 'SelectionType')))
                        
                        SState.dROILineX = [SState.dROILineX; SState.dROILineX(1)]; % Close line
                        SState.dROILineY = [SState.dROILineY; SState.dROILineY(1)];
                        
                        delete(SLines.hEval);
                        SState.iROIState = 0;
                        set(hF, 'WindowButtonMotionFcn',@fWindowMouseHoverFcn);
                        set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn);
                        set(hF, 'WindowButtonUpFcn', '');
                        fEval(SState.csEvalROIFcns);
                        return
                    end

                    switch get(hF, 'SelectionType')
                        
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % NORMAL selection: Add point to roi
                        case 'normal'
                            if ~SState.iROIState % This is the first polygon point
                                SState.dROILineX = dPos(1, 1);
                                SState.dROILineY = dPos(1, 2);
                                for i = 1:length(SPanels.hImg)
                                    if i + SState.iStartSeries - 1 > length(SData), continue, end
                                    SLines.hEval(i) = line(SState.dROILineX, SState.dROILineY, ...
                                        'Parent'    , SAxes.hImg(i), ...
                                        'Color'     , SPref.dCOLORMAP(i,:),...
                                        'LineStyle' , '-');
                                end
                                SState.iROIState = 1;
                            else % Add point to existing polygone
                                SState.dROILineX = [SState.dROILineX; dPos(1, 1)];
                                SState.dROILineY = [SState.dROILineY; dPos(1, 2)];
                                set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                            end
                            % End of NORMAL selection
                            % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                            
                            % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                            % Right mouse button/shift key: UNDO last point, quit
                            % if is no point remains
                        case 'alt'
                            if ~SState.iROIState, return, end    % Only perform action if painting in progress
                            
                            if length(SState.dROILineX) > 1
                                SState.dROILineX = SState.dROILineX(1:end-1); % Delete last point
                                SState.dROILineY = SState.dROILineY(1:end-1);
                                dROILineX = [SState.dROILineX; dPos(1, 1)]; % But draw line to current cursor position
                                dROILineY = [SState.dROILineY; dPos(1, 2)];
                                set(SLines.hEval, 'XData', dROILineX, 'YData', dROILineY);
                            else % Abort drawing ROI
                                SState.iROIState = 0;
                                delete(SLines.hEval);
                                SLines = rmfield(SLines, 'hEval');
                                set(hF, 'WindowButtonMotionFcn',@fWindowMouseHoverFcn);
                                set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn); % Disable the button down function
                            end
                            % End of right click/shift-click
                            % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    end
                end
            % End of the ROI EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The LIVEWIRE EVALUATION tool
            case 'lw'
                set(hF, 'WindowButtonMotionFcn', @fWindowMouseMoveFcn);
                set(hF, 'WindowButtonDownFcn', '');
                set(hF, 'WindowButtonUpFcn', @fWindowButtonUpFcn); % But keep the button up function
                if iAxisInd ~= SMouse.iStartAxis, return, end
                
                dPos = get(SAxes.hImg(SMouse.iStartAxis), 'CurrentPoint');
                switch get(hF, 'SelectionType')
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % NORMAL selection: Add point to roi
                    case 'normal'
                        if ~SState.iROIState % This is the first polygon point
                            dImg = SData(SMouse.iStartAxis + SState.iStartSeries - 1).dImg(:,:,SData(SMouse.iStartAxis + SState.iStartSeries - 1).iActiveImage);
                            SState.dLWCostFcn = fLiveWireGetCostFcn(dImg);
                            SState.dROILineX = dPos(1, 1);
                            SState.dROILineY = dPos(1, 2);
                            for i = 1:length(SPanels.hImg)
                                if i + SState.iStartSeries - 1 > length(SData), continue, end
                                SLines.hEval(i) = line(SState.dROILineX, SState.dROILineY, ...
                                    'Parent'    , SAxes.hImg(i), ...
                                    'Color'     , SPref.dCOLORMAP(i,:),...
                                    'LineStyle' , '-');
                            end
                            SState.iROIState = 1;
                            SState.iLWAnchorList = zeros(200, 1);
                            SState.iLWAnchorInd  = 0;
                        else % Add point to existing polygone
                            [iXPath, iYPath] = fLiveWireGetPath(SState.iPX, SState.iPY, dPos(1, 1), dPos(1, 2));
                            if isempty(iXPath)
                                iXPath = dPos(1, 1);
                                iYPath = dPos(1, 2);
                            end
                            SState.dROILineX = [SState.dROILineX; double(iXPath(:))];
                            SState.dROILineY = [SState.dROILineY; double(iYPath(:))];
                            set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                        end
                        SState.iLWAnchorInd = SState.iLWAnchorInd + 1;
                        SState.iLWAnchorList(SState.iLWAnchorInd) = length(SState.dROILineX); % Save the previous path length for the undo operation
                        [SState.iPX, SState.iPY] = fLiveWireCalcP(SState.dLWCostFcn, dPos(1, 1), dPos(1, 2), SPref.dLWRADIUS);
                    % End of NORMAL selection
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Right mouse button/shift key: UNDO last point, quit
                    % if is no point remains
                    case 'alt'
                        if SState.iROIState
                            SState.iLWAnchorInd = SState.iLWAnchorInd - 1;
                            if SState.iLWAnchorInd
                                SState.dROILineX = SState.dROILineX(1:SState.iLWAnchorList(SState.iLWAnchorInd)); % Delete last point
                                SState.dROILineY = SState.dROILineY(1:SState.iLWAnchorList(SState.iLWAnchorInd));
                                set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                                drawnow;
                                [SState.iPX, SState.iPY] = fLiveWireCalcP(SState.dLWCostFcn, SState.dROILineX(end), SState.dROILineY(end), SPref.dLWRADIUS);
                                fWindowMouseMoveFcn(hObject, []);
                            else % Abort drawing ROI
                                SState.iROIState = 0;
                                delete(SLines.hEval);
                                SLines = rmfield(SLines, 'hEval');
                                set(hF, 'WindowButtonMotionFcn',@fWindowMouseHoverFcn);
                                set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn);
                            end
                        end
                    % End of right click/shift-click
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - - 

                    % Middle mouse button/double-click/cntl-click: CLOSE
                    % POLYGONE and quit roi action
                    case {'extend', 'open'} % Middle mouse button or double-click -> 
                        if ~SState.iROIState, return, end    % Only perform action if painting in progress
                        
                        [iXPath, iYPath] = fLiveWireGetPath(SState.iPX, SState.iPY, dPos(1, 1), dPos(1, 2));
                        if isempty(iXPath)
                            iXPath = dPos(1, 1);
                            iYPath = dPos(1, 2);
                        end
                        SState.dROILineX = [SState.dROILineX; double(iXPath(:))];
                        SState.dROILineY = [SState.dROILineY; double(iYPath(:))];
                        
                        [SState.iPX, SState.iPY] = fLiveWireCalcP(SState.dLWCostFcn, dPos(1, 1), dPos(1, 2), SPref.dLWRADIUS);
                        [iXPath, iYPath] = fLiveWireGetPath(SState.iPX, SState.iPY, SState.dROILineX(1), SState.dROILineY(1));
                        if isempty(iXPath)
                            iXPath = SState.dROILineX(1);
                            iYPath = SState.dROILineX(2);
                        end
                        SState.dROILineX = [SState.dROILineX; double(iXPath(:))];
                        SState.dROILineY = [SState.dROILineY; double(iYPath(:))];
                        set(SLines.hEval, 'XData', SState.dROILineX, 'YData', SState.dROILineY);
                        
                        delete(SLines.hEval);
                        SState.iROIState = 0;
                        set(hF, 'WindowButtonMotionFcn',@fWindowMouseHoverFcn);
                        set(hF, 'WindowButtonDownFcn', @fWindowButtonDownFcn);
                        set(hF, 'WindowButtonUpFcn', '');
                        fEval(SState.csEvalROIFcns);

                    % End of middle mouse button/double-click/cntl-click
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                end
            % End of the LIVEWIRE EVALUATION tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The REGION GROWING tool
            case 'rg'
                if ~strcmp(get(hF, 'SelectionType'), 'normal'), return, end; % Otherwise calling the context menu starts a rg
                if ~iAxisInd || iAxisInd > length(SData), return, end;

                iSeriesInd = iAxisInd + SState.iStartSeries - 1;
                iSize = size(SData(iSeriesInd).dImg);
                dPos = get(SAxes.hImg(iAxisInd), 'CurrentPoint');
                if dPos(1, 1) < 1 || dPos(1, 2) < 1 || dPos(1, 1) > iSize(2) || dPos(1, 2) > iSize(1), return, end
                
                fEval(SState.csEvalVolFcns);
            % End of the REGION GROWING tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ISOCONTOUR tool
            case 'ic'
                if ~iAxisInd || iAxisInd > length(SData), return, end;
                
                iSeriesInd = iAxisInd + SState.iStartSeries - 1;
                iSize = size(SData(iSeriesInd).dImg);
                dPos = get(SAxes.hImg(iAxisInd), 'CurrentPoint');
                if dPos(1, 1) < 1 || dPos(1, 2) < 1 || dPos(1, 1) > iSize(2) || dPos(1, 2) > iSize(1), return, end
                
                fEval(SState.csEvalVolFcns);
            % End of the ISOCONTOUR tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The PROPERTIES tool: Rename the data
            case 'tag'
                if ~iAxisInd || iAxisInd > length(SData), return, end;
                
                iSeriesInd = SState.iStartSeries + iAxisInd - 1;
                csPrompt = {'Name', 'Voxel Size', 'Units', 'Orientation (''cor''/''tra''/''sag'') or (e.g. cor: ''RLHFAP'' in matlab axis)'};
                dDim = SData(iSeriesInd).dPixelSpacing;
                sDim = sprintf('%4.2f x ', dDim([2, 1, 3]));
                csVal = {SData(iSeriesInd).sName, sDim(1:end-3), SData(iSeriesInd).sUnits, SData(iSeriesInd).sOri};
                csAns    = inputdlg(csPrompt, sprintf('Change %s', SData(iSeriesInd).sName), 1, csVal);
                if isempty(csAns), return, end
                
                sName = csAns{1};
                iInd = find([SData.iGroupIndex] == SData(iSeriesInd).iGroupIndex);
                if length(iInd) > 1
                    if ~isnan(str2double(sName(end - 1:end))), sName = sName(1:end - 2); end % Crop the number
                end
                dDim = cell2mat(textscan(csAns{2}, '%fx%fx%f'));
                iCnt = 1;
                for i = iInd
                    if length(iInd) > 1
                        SData(i).sName = sprintf('%s%02d', sName, iCnt);
                    else
                        SData(i).sName = sName;
                    end
                    SData(i).dPixelSpacing  = dDim([2, 1, 3]);
                    SData(i).sUnits = csAns{3};
                    iCnt = iCnt + 1;
                end
                SData(iSeriesInd).sOri = fGetOrientation(csAns{4},SData(iSeriesInd).sOri);
                fFillPanels;
            % End of the TAG tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        end
        % end of the tool switch-statement
        % -----------------------------------------------------------------

        fUpdateActivation();
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonUpFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fKeyPressFcn (nested in imagine)
    % * * 
    % * * Figure callback
    % * *
    % * * Callback for keyboard actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fKeyPressFcn(hObject, eventdata)
        % -----------------------------------------------------------------
        % Bail if only a modifier has been pressed
        switch eventdata.Key
            case {'shift', 'control', 'alt'}, return
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get the modifier (shift, cntl, alt) keys and determine whether
        % the control key was pressed
        csModifier = eventdata.Modifier;
        sModifier = '';
        for i = 1:length(csModifier)
            if strcmp(csModifier{i}, 'shift'  ), sModifier = 'Shift'; end
            if strcmp(csModifier{i}, 'control'), sModifier = 'Cntl'; end
            if strcmp(csModifier{i}, 'alt'    ), sModifier = 'Alt'; end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Look for buttons with corresponding accelerators/modifiers
        for i = 1:length(SIcons)
            if strcmp(SIcons(i).Accelerator, eventdata.Key) && ...
               strcmp(SIcons(i).Modifier, sModifier)
                fIconClick(SImg.hIcons(i), eventdata);
            end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Functions not implemented by buttons
        switch eventdata.Key
            case {'numpad1', 'leftarrow'} % Image up
                fChangeImage(hObject, -1);
                
            case {'numpad2', 'rightarrow'} % Image down
                fChangeImage(hObject, 1);
                
            case {'numpad4', 'uparrow'} % Series up
                SState.iStartSeries = max([1 SState.iStartSeries - 1]);
                fFillPanels();
                fUpdateActivation();
                fWindowMouseHoverFcn(hObject, eventdata); % Update the cursor value

            case {'numpad5', 'downarrow'} % Series down
                SState.iStartSeries = min([SState.iStartSeries + 1 length(SData)]);
                SState.iStartSeries = max([SState.iStartSeries 1]);
                fFillPanels();
                fUpdateActivation();
                fWindowMouseHoverFcn(hObject, eventdata); % Update the cursor value
                
            case '2' % 4th dim up
                fChangeNDim(hObject, [1 0]);
                
            case '1' % 4th dim down
                fChangeNDim(hObject, [-1 0]);
                
            case '4' % 5th dim up
                fChangeNDim(hObject, [0 1]);
                
            case '3' % 5th dim down
                fChangeNDim(hObject, [0 -1]);
               
            case 'space' % Cycle Tools
                iTools = find([SIcons.GroupIndex] == 255 & [SIcons.Enabled]);
                iToolInd = find(strcmp({SIcons.Name}, SState.sTool));
                iToolIndInd = find(iTools == iToolInd);
                iTools = [iTools(end), iTools, iTools(1)];
                if ~strcmp(sModifier, 'Shift'), iToolIndInd = iToolIndInd + 2; end
                iToolInd = iTools(iToolIndInd);
                fIconClick(SImg.hIcons(iToolInd), eventdata);
                
        end
        % -----------------------------------------------------------------
        set(hF, 'SelectionType', 'normal');
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fKeyPressFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fContextFcn (nested in imagine)
    % * * 
    % * * Menu callback
    % * *
    % * * Callback for context menu clicks
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fContextFcn(hObject, eventdata)
        switch get(hObject, 'Label')
            case 'Tolerance +50%', SState.dTolerance = SState.dTolerance.*1.5;
            case 'Tolerance +10%', SState.dTolerance = SState.dTolerance.*1.1;
            case 'Tolerance -10%', SState.dTolerance = SState.dTolerance./1.1;
            case 'Tolerance -50%', SState.dTolerance = SState.dTolerance./1.5;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fContextFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fEval (nested in imagine)
    % * * 
    % * * Do the evaluation of line/ROIs
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fEval(csFcns)
        dPos = get(SAxes.hImg(fGetPanel), 'CurrentPoint');
        
        % -----------------------------------------------------------------
        % Depending on the time series setting, eval only visible or all data
        if fIsOn('clock')
            iSeries = 1:length(SData); % Eval all series or ND-data
        else
            iSeries = 1:length(SData);
            iSeries = iSeries(iSeries >= SState.iStartSeries & iSeries < SState.iStartSeries + length(SPanels.hImg));
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get the rawdata for evaluation and the distance/area/volume
        csSeriesName    = cell(length(iSeries), 1);
        cData           = cell(length(iSeries), 1);       
        if(any(strcmp(csFcns,'fFeaturesOLD')))
            iFeatures       = 21; 
        elseif(any(strcmp(csFcns,'fFeatures')))
            iFeatures       = 45;
        else
            iFeatures       = 0;            
        end
        iNDmax = [1, 1];
        for iSeriesInd = 1:length(SData)
            if(SData(iSeriesInd).lND)
                iNDmax = [max([iNDmax(1), size(SData(iSeriesInd).dImgAll,4)]), max([iNDmax(2), size(SData(iSeriesInd).dImgAll,5)])];
            end
        end
        dMeasures       = zeros(length(iSeries), length(csFcns) + iFeatures, iNDmax(1), iNDmax(2));
        csName          = cell(1, length(csFcns) + iFeatures);
        csUnitString    = cell(1, length(csFcns) + iFeatures);
        
        % -----------------------------------------------------------------
        % Series Loop
        for i = 1:length(iSeries)
            iSeriesInd = iSeries(i);
            csSeriesName{i} = SData(i).sName;
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Tool dependent code
            switch SState.sTool
                case 'line'
                    dXStart = SMouse.dAxesStartPos(1,1);    dYStart = SMouse.dAxesStartPos(1,2);
                    dXEnd   = dPos(1,1);                    dYEnd = dPos(1,2);
                    dDist = sqrt(((dXStart - dXEnd).*SData(iSeriesInd).dPixelSpacing(2)).^2 + ((dYStart - dYEnd).*SData(iSeriesInd).dPixelSpacing(1)).^2);
                    if dDist < 1.0, return, end % In case of a misclick
                    
                    csName{1} = 'Length';
                    csUnitString{1} = sprintf('%s', SData(iSeriesInd).sUnits);
                    dMeasures(i, 1, 1, 1) = dDist;
                    cData{i}    = improfile(fGetImg(iSeriesInd), [dXStart dXEnd], [dYStart, dYEnd], round(dDist), 'bilinear');
                
                case {'roi', 'lw'}
                    csName{1} = 'Area';
                    csUnitString{1} = sprintf('%s^2', SData(iSeriesInd).sUnits);
                    dImg = fGetImg(iSeriesInd);
                    lMask = poly2mask(SState.dROILineX, SState.dROILineY, size(dImg, 1), size(dImg, 2));
                    dMeasures(i, 1, 1, 1) = nnz(lMask).*SData(iSeriesInd).dPixelSpacing(2).*SData(iSeriesInd).dPixelSpacing(1);
                    cData{i} = dImg(lMask);
                    SData(iSeriesInd).lMask = false(size(SData(iSeriesInd).dImg));
                    SData(iSeriesInd).lMask(:,:,SData(iSeriesInd).iActiveImage) = lMask;
                    fFillPanels;
            
                case 'rg'
                    csName{1} = 'Volume';
                    csUnitString{1} = sprintf('%s^3', SData(iSeriesInd).sUnits);
                    if strcmp(SState.sDrawMode, 'phase')
                        dImg = angle(SData(iSeriesInd).dImg);
                    else
                        dImg = SData(iSeriesInd).dImg;
                        if ~isreal(dImg), dImg = abs(dImg); end
                    end
                    if i == 1 % In the first series detrmine the tolerance and use the same tolerance in the other series
                        [lMask, dTol] = fRegionGrowingAuto_mex(dImg, int16([dPos(1, 2); dPos(1, 1); SData(iSeriesInd).iActiveImage]), -1, SState.dTolerance);
                    else
                        lMask         = fRegionGrowingAuto_mex(dImg, int16([dPos(1, 2); dPos(1, 1); SData(iSeriesInd).iActiveImage]), dTol);
                    end
                    dMeasures(i, 1, 1, 1) = nnz(lMask).*prod(SData(iSeriesInd).dPixelSpacing);
                    cData{i} = dImg(lMask);
                    SData(iSeriesInd).lMask = lMask;
                    fFillPanels;
                    
                case 'ic'
                    csName{1} = 'Volume';
                    csUnitString{1} = sprintf('%s^3', SData(iSeriesInd).sUnits);
                    if strcmp(SState.sDrawMode, 'phase')
                        dImg = angle(SData(iSeriesInd).dImg);
                    else
                        dImg = SData(iSeriesInd).dImg;
                        if ~isreal(dImg), dImg = abs(dImg); end
                    end
                    lMask = fIsoContour_mex(dImg, int16([dPos(1, 2); dPos(1, 1); SData(iSeriesInd).iActiveImage]), 0.5);
                    dMeasures(i, 1, 1, 1) = nnz(lMask).*prod(SData(iSeriesInd).dPixelSpacing);
                    cData{i} = dImg(lMask);
                    SData(iSeriesInd).lMask = lMask;
                    fFillPanels;

            end
            % End of switch SState.sTool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Do the evaluation
            sEvalString = sprintf('%s=%s%s;', csName{1}, num2str(dMeasures(i, 1, 1, 1)), csUnitString{1});
            
            if(SData(iSeriesInd).lND)
                if(fIsOn('clock'))
                    nDims = {1:size(SData(iSeriesInd).dImgAll,4), 1:size(SData(iSeriesInd).dImgAll,5)};
                else
                    nDims = {SData(iSeriesInd).iActiveND(1), SData(iSeriesInd).iActiveND(2)};
                end
            else
                nDims = {1 1};
            end
            for i5D = nDims{2}
                for i4D = nDims{1}
                    if(SData(iSeriesInd).lND)
                       dImg = SData(iSeriesInd).dImgAll(:,:, SData(iSeriesInd).iActiveImage, i4D, i5D);
                       if(strcmp(SState.sTool, 'line'))
                           cData{i}  = improfile(fGetImgAll(iSeriesInd), [dXStart dXEnd], [dYStart, dYEnd], round(dDist), 'bilinear');
                       else
                           cData{i} = dImg(lMask);
                       end                
                    end
                    iCnt = 2;
                    for iJ = 2:length(csFcns) + 1
                        if(strcmp(csFcns{iJ-1},'fFeaturesOLD'))
                            [dMeasures(i,iCnt:iCnt+iFeatures-1, i4D, i5D), csName(iCnt:iCnt+iFeatures-1), sUnitFormat] = fFeaturesOLD(dImg, lMask);
                            iCnt = iCnt + iFeatures;
                        elseif(strcmp(csFcns{iJ-1},'fFeatures'))
                            [dMeasures(i,iCnt:iCnt+iFeatures-1, i4D, i5D), csName(iCnt:iCnt+iFeatures-1), sUnitFormat] = fFeatures(dImg, lMask);
                            iCnt = iCnt + iFeatures;
                        elseif(strcmp(csFcns{iJ-1},'fMask'))
                            % Export to file if enabled
                            if isempty(SState.sEvalFilename), return, end
                            iPos = fGetEvalFilePos;
                            [csName{iCnt}, csUnitString{iCnt}] = fMask(lMask, SData(iSeriesInd).iActiveImage, SState.sEvalFilename, iPos);
                            dMeasures(i, iCnt) = 1;
                            iCnt = iCnt + 1;
                        elseif(strcmp(csFcns{iJ-1},'fQuality'))
                            if(iSeriesInd == 1) % just show once
                                [dMeasures(:, iCnt, i4D, i5D), csName{iCnt}, sUnitFormat] = fQuality();
                            end
                            iCnt = iCnt + 1;
                        else
                            [dMeasures(i, iCnt, i4D, i5D), csName{iCnt}, sUnitFormat] = eval([csFcns{iJ - 1}, '(cData{i});']);
                            csUnitString{iCnt} = sprintf(sUnitFormat, SData(iSeriesInd).sUnits);
                            if isempty(csUnitString{iCnt}), csUnitString{iCnt} = ''; end
                            if(~SData(iSeriesInd).lND || (SData(iSeriesInd).lND && all(SData(iSeriesInd).iActiveND == [i4D, i5D])))
                                sEvalString = sprintf('%s %s=%s%s;', sEvalString, csName{iCnt}, num2str(dMeasures(i, iCnt)), csUnitString{iCnt});
                            end
                            iCnt = iCnt + 1;
                        end 
                    end
                end
            end
            SData(iSeriesInd).sEvalText = sEvalString;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
        end
        % End of series loop
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Plot the line profile and add name to legend
        % Check for presence of plot figure and create if necessary.
        if (fIsOn('line1') && fIsOn('clock')) || (fIsOn('line1') && ~fIsOn('clock') && strcmp(SState.sTool, 'line')) || (fIsOn('line1') && ~fIsOn('clock') && strcmp(SState.sTool, 'roi'))
            if ~ishandle(SState.hEvalFigure)
                SState.hEvalFigure = figure('Units', 'pixels', 'Position', [100 100 600, 400], 'NumberTitle', 'off');
                axes('Parent', SState.hEvalFigure);
                hold on;
            end
            hfig = figure(SState.hEvalFigure);
            set(hfig, 'Color', 'w');
            hL = findobj(SState.hEvalFigure, 'Type', 'line');
            hError = findobj(SState.hEvalFigure, 'Type', 'ErrorBar');
            hAEval = gca;
            delete(hL);
            delete(hError);

            if fIsOn('clock')
                for i = 2:size(dMeasures, 2)
                    plot(dMeasures(:,i, 1, 1), 'Color', SPref.dCOLORMAP(i - 1,:));
                end
                legend(csName{2:end}, 'Interpreter', 'None'); % Show legend
                set(SState.hEvalFigure, 'Name', 'Time Series');
                set(get(hAEval, 'XLabel'), 'String', 'Time Point');
                set(get(hAEval, 'YLabel'), 'String', 'Value');
            else
                if(strcmp(SState.sTool, 'line'))
                    for i = 1:length(cData)
                        plot(cData{i}, 'Color', SPref.dCOLORMAP(i,:));
                    end
                    legend(csSeriesName, 'Interpreter', 'None'); % Show legend
                    set(SState.hEvalFigure, 'Name', 'Line Profile');
                    set(get(hAEval, 'XLabel'), 'String', sprintf('x [%s]', SData(SState.iStartSeries).sUnits));
                    set(get(hAEval, 'YLabel'), 'String', 'Intensity');
                elseif(strcmp(SState.sTool, 'roi')) 
                    csLegendNames = {};
                    % find out along which dimension to show
                    if(size(dMeasures,3) == 1)
                        dMeasures = permute(dMeasures,[1 2 4 3]);
                    elseif(size(dMeasures,4) == 1)
%                         nothing to do -> last dimension
                    else
                        % show selection window
                        iSel = fWSImportSelection({sprintf('4th dimension: %d points', size(dMeasures,3)); sprintf('5th dimension: %d points', size(dMeasures,4))}, 'Select dimension');
                        if(iSel == 1)
                            iFrame = fWSImportSelection(num2cell(1:size(dMeasures,4)), 'Select frame in 5th dimension');
                            dMeasures = dMeasures(:,:,:,iFrame);
                        else
                            iFrame = fWSImportSelection(num2cell(1:size(dMeasures,3)), 'Select frame in 4th dimension');
                            dMeasures = permute(dMeasures(:,:,iFrame,:),[1 2 4 3]);
                        end
                    end
                    % check if mean and std can be plotted
                    iMeanIdx = find(strcmp(csFcns, 'fMean'));
                    iStdIdx = find(strcmp(csFcns, 'fStd'));
                    if(~isempty(iMeanIdx) && ~isempty(iStdIdx))
                        for iSeries = 1:size(dMeasures,1)
                            errorbar(squeeze(dMeasures(iSeries,iMeanIdx+1, :)), squeeze(dMeasures(iSeries,iStdIdx+1, :)), 'Color', SPref.dCOLORMAP(iSeries,:), 'Marker', SPref.cMarkers{iMeanIdx});
                            csLegendNames = cat(1,csLegendNames,[csSeriesName{iSeries},'_Mean+Std']);
                        end
                        iMeasureIdx = 2:size(dMeasures, 2);
                        iMeasureIdx([iMeanIdx, iStdIdx]) = [];
                    else
                        iMeasureIdx = 2:size(dMeasures, 2);
                    end
                    for i = iMeasureIdx
                        for iSeries = 1:size(dMeasures,1)
                            plot(squeeze(dMeasures(iSeries,i, :)), 'Color', SPref.dCOLORMAP(iSeries,:), 'Marker', SPref.cMarkers{i});
                            csLegendNames = cat(1,csLegendNames,[csSeriesName{iSeries},'_', csName{i}]);
                        end
                    end
                    legend(csLegendNames, 'Interpreter', 'None'); % Show legend
                    set(SState.hEvalFigure, 'Name', 'Evolution within series');
                    set(get(hAEval, 'XLabel'), 'String', 'Time Point');
                    set(get(hAEval, 'YLabel'), 'String', 'Value'); 
                end
            end
            
        end
        fFillPanels;
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Export to file if enabled
        if isempty(SState.sEvalFilename), return, end
        
        iPos = fGetEvalFilePos;
        if iPos < 0
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % File does not exist -> Write header
            fid = fopen(SState.sEvalFilename, 'w');
            if fid < 0, warning('IMAGINE: Cannot write to file ''%s''!', SState.sEvalFilename); return, end

            if fIsOn('clock')
                fprintf(fid, '\n'); % First line (series names) empty
                fprintf(fid, ['"";"";', fPrintCell('"%s";', csName), '\n']); % The eval function names
                fprintf(fid, ['"";"";', fPrintCell('"%s";', csUnitString), '\n']); % The eval function names
            else
                sFormatString = ['"%s";', repmat('"";', [1, length(csName) - 1])];
                fprintf(fid, ['"";"";', fPrintCell(sFormatString, csSeriesName), '\n']);
                fprintf(fid, ['"";"";', fPrintCell('"%s";', repmat(csName, [1, length(csSeriesName)])), '\n']); % The eval function names
                fprintf(fid, ['"";"";', fPrintCell('"%s";', repmat(csUnitString, [1, length(csSeriesName)])), '\n']); % The eval function names
            end
            
            fclose(fid);
            fprintf('Created file ''%s''!\n', SState.sEvalFilename);
            iPos = 0;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end

        % ----------------------------------------------------------------
        % Write the measurements to file
        fid = fopen(SState.sEvalFilename, 'a');
        if fid < 0, warning('IMAGINE: Cannot write to file ''%s''!', SState.sEvalFilename); return, end

        iPos = iPos + 1;
        if fIsOn('clock')
            fprintf(fid, '\n');
            for i = 1:length(csSeriesName)
                fprintf(fid, '"%d";"%s";', iPos, csSeriesName{i});
                if SPref.lGERMANEXPORT
                    for iJ = 1:size(dMeasures, 2), fprintf(fid, '"%s";', strrep(num2str(dMeasures(i, iJ)), '.', ',')); end
                else
                    for iJ = 1:size(dMeasures, 2), fprintf(fid, '"%s";', num2str(dMeasures(i, iJ))); end
                end
                fprintf(fid, '\n');
            end
        else
            fprintf(fid, '"%d";"";', iPos);
%             dMeasures = dMeasures';
            dMeasures = permute(dMeasures,[2 1 3 4]);
            dMeasures = dMeasures(:);
            if SPref.lGERMANEXPORT
                for i = 1:length(dMeasures), fprintf(fid, '"%s";', strrep(num2str(dMeasures(i)), '.', ',')); end
            else
                for i = 1:length(dMeasures), fprintf(fid, '"%s";', num2str(dMeasures(i))); end
            end
            fprintf(fid, '\n');
        end

        fclose(fid);
        fprintf('Written to position %d in file ''%s''!\n', iPos, SState.sEvalFilename);
        % -----------------------------------------------------------------
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fEval
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    function sString = fPrintCell(sFormatString, csCell)
        sString = '';
        for i = 1:length(csCell)
            sString = sprintf(['%s', sFormatString], sString, csCell{i});
        end
    end
    
	function iPos = fGetEvalFilePos
        iPos = -1;
        if ~exist(SState.sEvalFilename, 'file'), return, end

        fid = fopen(SState.sEvalFilename, 'r');
        if fid < 0, return, end

        iPos = 0; i = 1;
        sLine = fgets(fid);
        while ischar(sLine)
            csText{i} = sLine;
            sLine = fgets(fid);
            i = 1 + 1;
        end
        fclose(fid);

        csPos = textscan(csText{end}, '"%d"');
        if ~isempty(csPos{1}), iPos = csPos{1}; end
    end



    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fChangeImage (nested in imagine)
    % * *
    % * * Change image index of all series (if linked) or all selected
    % * * series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fChangeImage(hObject, iCnt)
        % -----------------------------------------------------------------
        % Return if projection image selected or ROI drawing in progress
        if strcmp(SState.sDrawMode, 'max') || strcmp(SState.sDrawMode, 'min') || SState.iROIState, return, end
        % -----------------------------------------------------------------
        
        if isstruct(iCnt), iCnt = iCnt.VerticalScrollCount; end % Origin is mouse wheel
        if isobject(iCnt), iCnt = iCnt.VerticalScrollCount; end % Origin is mouse wheel, R2014b
        % -----------------------------------------------------------------
        % Loop over all data (visible or not)
        for iSeriesInd = 1:length(SData)
            if (~fIsOn('link')) && (~SData(iSeriesInd).lActive), continue, end % Skip if axes not linked and current figure not active
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            iNewImgInd = SData(iSeriesInd).iActiveImage + iCnt;
            iNewImgInd = max([iNewImgInd, 1]);
            iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).dImg, 3)]);
            SData(iSeriesInd).iActiveImage = iNewImgInd;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Update corresponding axes if necessary (visible)
            iAxisInd = iSeriesInd - SState.iStartSeries + 1;
            if (iAxisInd) > 0 && (iAxisInd <= length(SPanels.hImgFrame))         % Update Corresponding Axis
                if(SData(iSeriesInd).lND) % 5D
                    set(STexts.hImg2(iAxisInd), 'String', sprintf('%u/%u [%u/%u, %u/%u]', SData(iSeriesInd).iActiveImage, size(SData(iSeriesInd).dImg, 3), SData(iSeriesInd).iActiveND(1), size(SData(iSeriesInd).dImgAll,4), SData(iSeriesInd).iActiveND(2), size(SData(iSeriesInd).dImgAll,5)));
                else
                    set(STexts.hImg2(iAxisInd), 'String', sprintf('%u/%u', iNewImgInd, size(SData(iSeriesInd).dImg, 3)));
                end
            end
        end
        fFillPanels;
        fWindowMouseHoverFcn(hObject, []); % Update the cursor value
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fChangeImage
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fChangeNDim (nested in imagine)
    % * *
    % * * Change 4th and 5th dimension index (if linked) or all selected
    % * * series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fChangeNDim(hObject, iCnts)
        % -----------------------------------------------------------------
        % Return if projection image selected or ROI drawing in progress
        if strcmp(SState.sDrawMode, 'max') || strcmp(SState.sDrawMode, 'min') || SState.iROIState, return, end
        % -----------------------------------------------------------------
    
        % -----------------------------------------------------------------
        % Loop over all data (visible or not)
        for iSeriesInd = 1:length(SData)
            if (~fIsOn('link')) && (~SData(iSeriesInd).lActive), continue, end % Skip if axes not linked, current figure not active and not N>4 dimensional
            
            if(~SData(iSeriesInd).lND), continue, end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            for iI=1:2
                iNewImgInd = SData(iSeriesInd).iActiveND(iI) + iCnts(iI);
                iNewImgInd = max([iNewImgInd, 1]);
                iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).dImgAll, 3+iI)]);
                SData(iSeriesInd).iActiveND(iI) = iNewImgInd;
            end
            SData(iSeriesInd).dImg = SData(iSeriesInd).dImgAll(:,:,:,SData(iSeriesInd).iActiveND(1),SData(iSeriesInd).iActiveND(2));
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Update corresponding axes if necessary (visible)
            iAxisInd = iSeriesInd - SState.iStartSeries + 1;
            if (iAxisInd) > 0 && (iAxisInd <= length(SPanels.hImgFrame))         % Update Corresponding Axis
                set(STexts.hImg2(iAxisInd), 'String', sprintf('%u/%u [%u/%u, %u/%u]', SData(iSeriesInd).iActiveImage, size(SData(iSeriesInd).dImg, 3), SData(iSeriesInd).iActiveND(1), size(SData(iSeriesInd).dImgAll,4), SData(iSeriesInd).iActiveND(2), size(SData(iSeriesInd).dImgAll,5)));
            end
        end
        fFillPanels;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fChangeNDim
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fSaveToFiles (nested in imagine)
    % * * 
    % * * Save image data of selected panels to file(s)
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fSaveToFiles(sFilename, sPath, lCurrSlice)
        
%         if(nargin < 4)
%             sAppend = '';
%         end        
        if(nargin < 3)
            lCurrSlice = false;
        end
        set(hF, 'Pointer', 'watch'); drawnow
        iNSeries = fGetNVisibleSeries;
        dMin = SData(SState.iStartSeries).dWindowCenter - 0.5.*SData(SState.iStartSeries).dWindowWidth;
        dMax = SData(SState.iStartSeries).dWindowCenter + 0.5.*SData(SState.iStartSeries).dWindowWidth;
        for i = 1:iNSeries
            sAppend = [];
            iSeriesInd = i + SState.iStartSeries - 1;
            lND = SData(iSeriesInd).lND;
            if ~fIsOn('link1')
                dMin = SData(iSeriesInd).dWindowCenter - 0.5.*SData(iSeriesInd).dWindowWidth;
                dMax = SData(iSeriesInd).dWindowCenter + 0.5.*SData(iSeriesInd).dWindowWidth;
            end
            if strcmp(SState.sDrawMode, 'phase')
                dMin = -pi;
                dMax =  pi;
            end
            switch SState.sDrawMode
                case {'mag', 'phase'}
                    if(lND)
                        iSize = size(SData(iSeriesInd).dImgAll);
                        if(ndims(iSize) < 5)
                            iSize = [iSize, 1];
                        end
                    else
                        iSize = [size(SData(iSeriesInd).dImg), 1, 1, 1];
                    end
                    if(lCurrSlice)
                        dImg = zeros([iSize(1:2), 1]);
                    else
                        dImg = zeros([iSize(1:2), prod(iSize(3:end))]);
                    end
                    iCnt = 1;
                    for i5D = 1:iSize(5)
                        for i4D = 1:iSize(4)
                            for iJ = 1:size(SData(iSeriesInd).dImg, 3)
                                if(lCurrSlice && (iJ ~= SData(iSeriesInd).iActiveImage || i4D ~= SData(iSeriesInd).iActiveND(1) || i5D ~= SData(iSeriesInd).iActiveND(2)))
                                   continue; 
                                end
                                dImg(:,:,iCnt) = fGetImgAll(iSeriesInd, iJ, i4D, i5D);
                                iCnt = iCnt + 1;
                                sAppend = cat(1,sAppend, [iJ, i4D, i5D]);
                            end
                        end
                    end
                case {'min', 'max'}
                    dImg = fGetImg(iSeriesInd);
            end
            dImg = dImg - dMin;
            iImg = uint8(dImg./(dMax - dMin).*255) + 1;
            dImg = reshape(SState.dColormapBack(iImg, :), [size(iImg, 1), size(iImg, 2), size(iImg, 3), 3]);
            dImg = permute(dImg, [1 2 4 3]); % rgb mode
            dImg = dImg.*255;
            dImg(dImg < 0) = 0;
            dImg(dImg > 255) = 255;
            sSeriesFilename = strrep(sFilename, '%SeriesName%', SData(iSeriesInd).sName);
                        
            switch SState.sDrawMode
                case {'mag', 'phase'}
                    hW = waitbar(0, sprintf('Saving Stack ''%s''', SData(iSeriesInd).sName));
                    for iImgInd = 1:size(dImg, 4)
%                         if(lCurrSlice && iImgInd ~= SData(iSeriesInd).iActiveImage)
%                            continue; 
%                         end
                        
                        if(SData(iSeriesInd).lND)
                            sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%03u', sAppend(iImgInd,1)));
                            [~, sFileCurr, sExtCurr] = fileparts(sImgFilename);
                            sImgFilename = [sFileCurr, sprintf('_%03u_%03u', sAppend(iImgInd,2), sAppend(iImgInd,3)), sExtCurr];
%                             if(isempty(sAppend))
%                                 sImgFilename = [sFileCurr, sprintf('_%03u_%03u', SData(iSeriesInd).iActiveND(1), SData(iSeriesInd).iActiveND(2)), sExtCurr];
%                             else
%                                 sImgFilename = [sFileCurr, sAppend, sExtCurr];
%                             end
                        else
                            sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%03u', iImgInd));
                        end
                        if(lCurrSlice && ~isempty(SData(iSeriesInd).dFlow) && SPref.iQUIVERFACTOR > 0 && SPref.iQUIVERSTRENGTH > 0)
                            screencapture(SAxes.hImg(i), [sPath, filesep, sImgFilename]);
                        else
                            imwrite(uint8(dImg(:,:,:,iImgInd)), [sPath, filesep, sImgFilename]);
                        end
                        waitbar(iImgInd./size(dImg, 4), hW); drawnow;
                    end
                    close(hW);
                case {'max', 'min'}
                    sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%sProjection', SState.sDrawMode));
                    if(SData(iSeriesInd).lND)
                        [~, sFileCurr, sExtCurr] = fileparts(sImgFilename);
                        sImgFilename = [sFileCurr, sprintf('_%03u_%03u', SData(iSeriesInd).iActiveND(1), SData(iSeriesInd).iActiveND(2)), sExtCurr];
                    end
                    imwrite(uint8(dImg), [sPath, filesep, sImgFilename]);
            end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
        end
        set(hF, 'Pointer', 'arrow');
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fSaveToFiles
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fSaveMaskToFiles (nested in imagine)
    % * * 
    % * * Save image data of selected panels to file(s)
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fSaveMaskToFiles(sFilename, sPath)

        set(hF, 'Pointer', 'watch'); drawnow
        iNSeries = fGetNVisibleSeries;
        for i = 1:iNSeries
            iSeriesInd = i + SState.iStartSeries - 1;
            lImg = SData(iSeriesInd).lMask;
            if isempty(lImg), continue, end
            
            lMask = max(max(lImg, [], 1), [], 2);
            dImg = double(lImg);
            switch nnz(lMask)
                case 0, continue % no mask
                    
                case 1 % its a 2D mask
                    iInd = find(lMask);
                    sSeriesFilename = strrep(sFilename, '%SeriesName%', SData(iSeriesInd).sName);
                    sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%03d', iInd));
                    imwrite(dImg(:,:,iInd), [sPath, filesep, sImgFilename]);
                otherwise
                    sSeriesFilename = strrep(sFilename, '%SeriesName%', SData(iSeriesInd).sName);
                    for iInd = 1:size(dImg, 3)
                        sImgFilename = strrep(sSeriesFilename, '%ImageNumber%', sprintf('%03d', iInd));
                        imwrite(dImg(:,:,iInd), [sPath, filesep, sImgFilename]);
                    end
            end
        end
        set(hF, 'Pointer', 'arrow');
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fSaveToFiles
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fFillPanels (nested in imagine)
    % * *
    % * * Display the current data in all panels.
    % * * The holy grail of Imagine!
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fFillPanels
        for i = 1:length(SPanels.hImgFrame)
            iSeriesInd = SState.iStartSeries + i - 1;
            if iSeriesInd <= length(SData) % Panel not empty
                
                if strcmp(SState.sDrawMode, 'phase')
                    dMin = -pi; dMax = pi;
                else
                    dMin = SData(SState.iStartSeries).dWindowCenter - 0.5.*SData(SState.iStartSeries).dWindowWidth;
                    dMax = SData(SState.iStartSeries).dWindowCenter + 0.5.*SData(SState.iStartSeries).dWindowWidth;
                end
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Get the image data, do windowing and apply colormap
                if ~fIsOn('link1') && ~strcmp(SState.sDrawMode, 'phase')
                    dMin = SData(iSeriesInd).dWindowCenter - 0.5.*SData(iSeriesInd).dWindowWidth;
                    dMax = SData(iSeriesInd).dWindowCenter + 0.5.*SData(iSeriesInd).dWindowWidth;
                end
                dImg = fGetImg(iSeriesInd);
                dImg = dImg - dMin;
                iImg = uint8(dImg./(dMax - dMin).*255) + 1;
                dImg = reshape(SState.dColormapBack(iImg, :), [size(iImg, 1) ,size(iImg, 2), 3]);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Apply mask if any
                if ~isempty(SData(iSeriesInd).lMask)
                    dColormap = [0 0 0; SPref.dCOLORMAP(i, :)];
                    switch SState.sDrawMode
                        case {'mag', 'phase'}, iMask = uint8(SData(iSeriesInd).lMask(:,:,SData(iSeriesInd).iActiveImage)) + 1;
                        case {'max', 'min'}  , iMask = uint8(max(SData(iSeriesInd).lMask, [], 3)) + 1;
                    end
                    dMask = reshape(dColormap(iMask, :), [size(iMask, 1) ,size(iMask, 2), 3]);
                    dImg = 1 - (1 - dImg).*(1 - SState.dMaskOpacity.*dMask); % The 'screen' overlay mode
                end
                set(SImg.hImg(i), 'CData', dImg);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Apply flow if any
                if ~isempty(SData(iSeriesInd).dFlow)
                    if(SPref.iQUIVERFACTOR > 0 && SPref.iQUIVERSTRENGTH > 0)
                        iFlow = fGetFlow(iSeriesInd, SData(iSeriesInd).iActiveImage, SData(iSeriesInd).iActiveND(1), SData(iSeriesInd).iActiveND(2));
%                         dMaxFlow = max(iFlow(:));
                        iScale = SPref.iQUIVERSTRENGTH/100; % correct length for sparser visualization
                        [xq, yq] = ndgrid(1:size(iFlow,1), 1:size(iFlow,2));
                        xq = xq(1:SPref.iQUIVERFACTOR:end, 1:SPref.iQUIVERFACTOR:end); 
                        yq = yq(1:SPref.iQUIVERFACTOR:end, 1:SPref.iQUIVERFACTOR:end);
                        set(SImg.hQ(i), 'XData', floor(yq), 'YData', floor(xq), ...
                                        'UData', iScale.*iFlow(1:SPref.iQUIVERFACTOR:end, 1:SPref.iQUIVERFACTOR:end, 1), ...
                                        'VData', iScale.*iFlow(1:SPref.iQUIVERFACTOR:end, 1:SPref.iQUIVERFACTOR:end, 2), ...
                                        'WData', zeros([size(xq,1), size(xq,2)]), ...
                                        'Color', SPref.iQUIVERCOLOR, ...
                                        'Visible', 'on');
                    else
                        set(SImg.hQ(i), 'Visible', 'off');
                    end
                end
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Handle zoom and shift
                dPos = get(SPanels.hImg(i), 'Position');
                dScale = SData(iSeriesInd).dPixelSpacing;
                dScale = dScale(2:-1:1)./min(dScale); % Smallest Entry scaled to 1
                dDim = [size(dImg, 2), size(dImg, 1)]; % Swap x and y
                dSize = dDim.*SData(iSeriesInd).dZoomFactor.*dScale;
                set(SAxes.hImg(i), ...
                    'Position', [SData(iSeriesInd).dDrawCenter.*dPos(3:4) - dSize./2, dSize], ...
                    'XLim'    , [0.5 dDim(1) + 0.5], ...
                    'YLim'    , [0.5 dDim(2) + 0.5]);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Update the text elements
                set(STexts.hColorbarMin(i), 'String', sprintf('%s', fPrintNumber(dMin)));
                set(STexts.hColorbarMax(i), 'String', sprintf('%s', fPrintNumber(dMax)));
                set(STexts.hImg1(i), 'String', ['[', int2str(iSeriesInd), ']: ', SData(iSeriesInd).sName]);
                if strcmp(SState.sDrawMode, 'max') || strcmp(SState.sDrawMode, 'min')
                    set(STexts.hImg2(iSeriesInd), 'String', 'Projection');
                else
                    if(SData(iSeriesInd).lND)
                        set(STexts.hImg2(i), 'String', sprintf('%u/%u [%u/%u, %u/%u]', SData(iSeriesInd).iActiveImage, size(SData(iSeriesInd).dImg, 3), SData(iSeriesInd).iActiveND(1), size(SData(iSeriesInd).dImgAll,4), SData(iSeriesInd).iActiveND(2), size(SData(iSeriesInd).dImgAll,5)));
                    else
                        set(STexts.hImg2(i), 'String', sprintf('%u/%u', SData(iSeriesInd).iActiveImage, size(SData(iSeriesInd).dImg, 3)));
                    end
                end
                set(STexts.hEval(i), 'String', SData(iSeriesInd).sEvalText);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
            else % Panel is empty
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Set image to the background image (RGB)
                set(SImg.hImg(i), 'CData', SAp.dEmptyImg);
                dXDim = size(SAp.dEmptyImg, 2);
                dYDim = size(SAp.dEmptyImg, 1);
                set(SAxes.hImg(i), 'Position', [1 1 dXDim, dYDim], 'XLim', [0.5 dXDim + 0.5], 'YLim', [0.5 dYDim + 0.5]);
                set(STexts.hImg1(i), 'String', '<no data>');
                set(STexts.hImg2(i), 'String', '');
                set([STexts.hEval(i), STexts.hVal(i)], 'String', '');
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fFillPanels
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetFlow (nested in imagine)
    % * *
    % * * Return flow for view according to drawmode
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dFlow = fGetFlow(iInd, iImgInd, i4D, i5D)
        if nargin < 4, i5D = SData(iInd).iActiveND(1); end
        if nargin < 3, i4D = SData(iInd).iActiveND(2); end
        if nargin < 2, iImgInd = SData(iInd).iActiveImage; end
        if(SData(iInd).lND)
            if(ndims(SData(iInd).dImgAll) == 5) % 5D
                dFlow = squeeze(SData(iInd).dFlow(:,:,iImgInd,i4D,i5D,:));
            else % 4D
                dFlow = squeeze(SData(iInd).dFlow(:,:,iImgInd,i4D,:));
            end
        else
            if(ndims(SData(iInd).dImg) == 3) % 3D
                dFlow = squeeze(SData(iInd).dFlow(:,:,iImgInd,:));
            else % 2D
                dFlow = squeeze(SData(iInd).dFlow(:,:,:));
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetFlow
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

        
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetImgAll (nested in imagine)
    % * *
    % * * Return data for view according to drawmode
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImg = fGetImgAll(iInd, iImgInd, i4D, i5D)
        if nargin < 4, i5D = SData(iInd).iActiveND(1); end
        if nargin < 3, i4D = SData(iInd).iActiveND(2); end
        if nargin < 2, iImgInd = SData(iInd).iActiveImage; end
        
        if strcmp(SState.sDrawMode, 'phase')
            if(SData(iInd).lND)
                dImg = angle(SData(iInd).dImgAll(:,:,iImgInd, i4D, i5D));
            else
                dImg = angle(SData(iInd).dImg(:,:,iImgInd));
            end
            return
        end
        
        if(SData(iInd).lND)
            if(ndims(SData(iInd).dImgAll) == 5)
                dImg = SData(iInd).dImgAll(:,:,:,i4D,i5D);
            else % 4D
                dImg = SData(iInd).dImgAll(:,:,:,i4D);
            end
        else
            dImg = SData(iInd).dImg;
        end
        if ~isreal(dImg), dImg = abs(dImg); end
        
        switch SState.sDrawMode
            case 'mag', dImg = dImg(:,:,iImgInd);
            case 'max', dImg = max(dImg, [], 3);
            case 'min', dImg = min(dImg, [], 3);
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetImgAll
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetImg (nested in imagine)
    % * *
    % * * Return data for view according to drawmode
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImg = fGetImg(iInd, iImgInd)
        if nargin < 2, iImgInd = SData(iInd).iActiveImage; end
        
        if strcmp(SState.sDrawMode, 'phase')
            dImg = angle(SData(iInd).dImg(:,:,iImgInd));
            return
        end
        
        dImg = SData(iInd).dImg;
        if ~isreal(dImg), dImg = abs(dImg); end
        
        switch SState.sDrawMode
            case 'mag', dImg = dImg(:,:,iImgInd);
            case 'max', dImg = max(dImg, [], 3);
            case 'min', dImg = min(dImg, [], 3);
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetImg
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetOrientation (nested in imagine)
    % * *
    % * * Return correct image orientation in matlab coordinate axis
    % * *    ^ z
	% * *   /
    % * *  /
    % * *  -------> x
    % * *  |
    % * *  |
    % * *  v
    % * *   y
    % * * 
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function sOri = fGetOrientation(sInput, sDefault)
        if(strcmp(sInput, 'cor'))
            sOri = 'RLHFAP';
        elseif(strcmp(sInput,'tra'))
            sOri = 'RLAPFH';
        elseif(strcmp(sInput,'sag'))
            sOri = 'APHFLR';
        else
            if(length(sInput) == 6)
                sOri = sInput;
            else
                sOri = sDefault;
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetOrientation
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fCreatePanels (nested in imagine)
    % * *
    % * * Create the panels and its child object.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCreatePanels
        % -----------------------------------------------------------------
        % Delete panels and their handles if necessary
        if isfield(SPanels, 'hImgFrame')
            delete(SPanels.hImgFrame); % Deletes hImgFrame and its children
            SPanels = rmfield(SPanels, {'hImgFrame', 'hImg'});
            STexts  = rmfield(STexts,  {'hImg1', 'hImg2', 'hColorbarMin', 'hColorbarMax','hEval', 'hVal'});
            SAxes   = rmfield(SAxes,   {'hImg', 'hColorbar'});
            SImg    = rmfield(SImg,    {'hImg', 'hColorbar', 'hQ'});
        end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % For each panel create panels, axis, image and text objects
        for i = 1:prod(SState.iPanels)
            SPanels.hImgFrame(i) = uipanel(...
                'Parent'                , hF, ...
                'BackgroundColor'       , SAp.dBGCOLOR*0.6, ...
                'BorderWidth'           , 0, ...
                'BorderType'            , 'line', ...
                'Units'                 , 'pixels');
            SPanels.hImg(i) = uipanel(...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SState.dColormapBack(1,:), ...
                'BorderWidth'           , 0, ...
                'Units'                 , 'pixels');
            SAxes.hImg(i) = axes(...
                'Parent'                , SPanels.hImg(i), ...
                'Units'                 , 'pixels');
            SImg.hImg(i) = image(zeros(1, 'uint8'), ...
                'Parent'                , SAxes.hImg(i), ...
                'HitTest'               , 'off');
            hold(SAxes.hImg(i), 'on');
            SImg.hQ(i) = quiver(1, 1, zeros(1, 'double'), zeros(1, 'double'), 0, ...
                'Parent'                , SAxes.hImg(i), ...
                'AutoScale'             , 'off', ...
                'HitTest'               , 'off', ...
                'Linewidth'             , 1, ...
                'Color',                'y');
            hold(SAxes.hImg(i), 'off');
            SAxes.hColorbar(i) = axes(...
                'Parent'                , SPanels.hImgFrame(i), ...
                'Units'                 , 'pixels', ...
                'XAxisLocation'         , 'top');
            SImg.hColorbar(i)       = image(uint8(0:255), 'Parent', SAxes.hColorbar(i), 'ButtonDownFcn', @fSetWindow);
            STexts.hImg1(i)         = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            STexts.hImg2(i)         = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            STexts.hColorbarMin(i)  = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            STexts.hColorbarMax(i)  = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            STexts.hEval(i)         = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            STexts.hVal(i)          = uicontrol('Style', 'text', 'Parent', SPanels.hImgFrame(i));
            
            iDataInd = i + SState.iStartSeries - 1;
            if (iDataInd > 0) && (iDataInd <= length(SData))
                set(STexts.hColorbarMin(i), 'String', sprintf('%s', fPrintNumber(SData(iDataInd).dWindowCenter - SData(iDataInd).dWindowWidth./2)));
                set(STexts.hColorbarMax(i), 'String', sprintf('%s', fPrintNumber(SData(iDataInd).dWindowCenter + SData(iDataInd).dWindowWidth./2)));
            end
            
        end % of loop over pannels
        % -----------------------------------------------------------------
        
        axis(SAxes.hImg, 'off');
        set(SAxes.hColorbar, 'XAxisLocation', 'top', 'XTick', [], 'YTick', [], 'XTickLabel', [], 'Visible', 'on');
        set([STexts.hColorbarMin, STexts.hColorbarMax, STexts.hEval, STexts.hVal], ...
            'BackgroundColor'       , SAp.dBGCOLOR*0.6, ...
            'ForegroundColor'       , 'w', ...
            'HorizontalAlignment'   , 'left', ...
            'FontUnits'             , 'normalized', ...
            'FontSize'              , 0.8);
        set([STexts.hImg1, STexts.hImg2], ...
            'BackgroundColor'       , SAp.dBGCOLOR*0.6, ...
            'ForegroundColor'       , 'w', ...
            'HorizontalAlignment'   , 'left', ...
            'FontUnits'             , 'normalized', ...
            'FontSize'              , 0.8);
        set([STexts.hColorbarMin, STexts.hVal, STexts.hImg2], 'HorizontalAlignment', 'right');


        if strcmp(SState.sTool, 'rg'), set(SPanels.hImg, 'uicontextmenu', hContextMenu); end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCreatePanels
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    function fSetWindow(hObject, eventdata)
        iAxisInd = find(SImg.hColorbar == hObject);
        iSeriesInd = iAxisInd + SState.iStartSeries - 1;
        if iSeriesInd > length(SData), return, end
        
        dMin = SData(iSeriesInd).dWindowCenter - 0.5.*SData(iSeriesInd).dWindowWidth;
        dMax = SData(iSeriesInd).dWindowCenter + 0.5.*SData(iSeriesInd).dWindowWidth;
        csVal{1} = fPrintNumber(dMin);
        csVal{2} = fPrintNumber(dMax);
        csAns = inputdlg({'Min', 'Max'}, sprintf('Change %s windowing', SData(iSeriesInd).sName), 1, csVal);
        if isempty(csAns), return, end
        
        csVal = textscan([csAns{1}, ' ', csAns{2}], '%f %f');
        if ~isempty(csVal{1}), dMin = csVal{1}; end
        if ~isempty(csVal{2}), dMax = csVal{2}; end
        SData(iSeriesInd).dWindowCenter = (dMin + dMax)./2;
        SData(iSeriesInd).dWindowWidth  = (dMax - dMin);
        fFillPanels;
    end
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fUpdateActivation (nested in imagine)
    % * *
    % * * Set the activation and availability of some switches according to
    % * * the GUI state.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fUpdateActivation

        % -----------------------------------------------------------------
        % Update states of some menubar buttons according to panel selection
        csLabels = {SIcons.Name};
        SIcons(find(strcmp(csLabels, 'save')))      .Enabled = fGetNActiveVisibleSeries() > 0;
        SIcons(find(strcmp(csLabels, 'doc_delete'))).Enabled = fGetNActiveVisibleSeries() > 0;
        SIcons(find(strcmp(csLabels, 'exchange')))  .Enabled = fGetNActiveVisibleSeries() == 2;
        SIcons(find(strcmp(csLabels, 'record')))    .Enabled = isempty(SState.sEvalFilename);
        SIcons(find(strcmp(csLabels, 'stop')))      .Enabled = ~isempty(SState.sEvalFilename);
        SIcons(find(strcmp(csLabels, 'rewind')))    .Enabled = ~isempty(SState.sEvalFilename);
        % -----------------------------------------------------------------
        
        SIcons(find(strcmp(csLabels, 'lw'))).Enabled = exist('fLiveWireCalcP') == 3; % Compiled mex file
        SIcons(find(strcmp(csLabels, 'rg'))).Enabled = exist('fRegionGrowingAuto_mex') == 3; % Compiled mex file
        SIcons(find(strcmp(csLabels, 'ic'))).Enabled = exist('fIsoContour_mex') == 3; % Compiled mex file

        % -----------------------------------------------------------------
        % Treat the menubar items
        dScale = ones(length(SIcons));
        dScale(~[SIcons.Enabled]) = SAp.iDISABLED_SCALE;
        dScale( [SIcons.Enabled] & ~[SIcons.Active]) = SAp.iINACTIVE_SCALE;
        for i = 1:length(SIcons), set(SImg.hIcons(i), 'CData', SIcons(i).dImg.*dScale(i)); end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Treat the panels
        for i = 1:length(SPanels.hImgFrame)
            iSeriesInd = i + SState.iStartSeries - 1;
            if iSeriesInd > length(SData) || ~SData(iSeriesInd).lActive
                set([SPanels.hImgFrame(i), STexts.hImg1(i), STexts.hImg2(i), STexts.hColorbarMin(i), STexts.hColorbarMax(i), STexts.hEval(i), STexts.hVal(i)], 'BackgroundColor', SAp.dBGCOLOR.*0.6);
            else
                set([SPanels.hImgFrame(i), STexts.hImg1(i), STexts.hImg2(i), STexts.hColorbarMin(i), STexts.hColorbarMax(i), STexts.hEval(i), STexts.hVal(i)], 'BackgroundColor', SAp.dBGCOLOR);
            end
        end
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fUpdateActivation
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetNActiveVisibleSeries (nested in imagine)
    % * *
    % * * Returns the number of visible active series.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iNActiveSeries = fGetNActiveVisibleSeries()
        iNActiveSeries = 0;
        if isempty(SData), return, end
        
        iStartInd = SState.iStartSeries;
        iEndInd = min([iStartInd + length(SPanels.hImgFrame) - 1, length(SData)]);
        iNActiveSeries = nnz([SData(iStartInd:iEndInd).lActive]);
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetNActiveVisibleSeries
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetNVisibleSeries (nested in imagine)
    % * *
    % * * Returns the number of visible active series.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iNVisibleSeries = fGetNVisibleSeries()
        if isempty(SData)
            iNVisibleSeries = 0;
        else
            iNVisibleSeries = min([length(SPanels.hImgFrame), length(SData) - SState.iStartSeries + 1]);
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetNVisibleSeries
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fParseInputs (nested in imagine)
    % * *
    % * * Parse the varargin input variable. It can be either pairs of
    % * * data/captions or just data. Data can be either 2D, 3D or 4D.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fParseInputs(cInput)        
        
        iInd = 1;
        iDataInd = 0;
        
%         xInput = cInput{iInd};
%         if ~(isnumeric(xInput) || islogical(xInput)), error('First input must be image data of some kind!'); end
        
%         iDataInd = iDataInd + 1;
%         dImg = xInput;
%         sName = sprintf('Input_%02d', iDataInd);
%         dDim = [1 1 1];
%         sUnits = 'px';
%         dWindow = [];
%         lMask = [];
%         iInd = iInd + 1;
        
        while iInd <= length(cInput);
            xInput = cInput{iInd};
            if ~(isnumeric(xInput) || islogical(xInput) || ischar(xInput)), error('Argument %d expected to be either property or data!', iInd); end

            if isnumeric(xInput) || islogical(xInput) % New image data
                if iDataInd, fAddImageToData(dImg, sName, 'startup', dDim, sUnits, dWindow, lMask, dFlow); end% Add the last Dataset
                iDataInd = iDataInd + 1;
                dImg = xInput;
                sName = sprintf('Input_%02d', iDataInd);
                dDim = [1 1 1];
                sUnits = 'px';
                sOri = 'RLHFAP'; % default is coronal orientation
                dWindow = [];
                lMask = [];
                dFlow = [];
            end
            
            if ischar(xInput)
                iInd = iInd + 1;
                if iInd > length(cInput), error('Argument %d (property) must be followed by a value!', iInd - 1); end
                
                xVal = cInput{iInd};
                switch lower(xInput)
                    case {'n', 'name'}
                        if ~ischar(xVal), error('Name property must be a string!'); end
                        sName = xVal;
                    case {'v', 'voxelsize'}
                        if ~isnumeric(xVal) || numel(xVal) ~= 3, error('Voxelsize property must be a [3x1] or [1x3] numeric vector!'); end
                        dDim = xVal;
                    case {'u', 'units'}
                        if ~ischar(xVal), error('Units property must be a string!'); end
                        sUnits = xVal;
                    case {'w', 'window'}
                        if ~isnumeric(xVal) || numel(xVal) ~= 2, error('Window limits property must be a [2x1] or [1x2] numeric vector!'); end
                        dWindow = xVal;
                    case {'o', 'orientation'}
                        if ~ischar(xVal) || ~any(strcmp({'cor','sag','tra'},xVal)) || length(xVal) ~= 6, error('Orientation must be ''cor'', ''sag'', ''tra'' or a 6-character string, e.g. for coronal orientation (in matlab axis): ''RLHFAP'''); end;
                        sOri = xVal;
                    case {'m', 'mask'}
                        if ~islogical(xVal) || ndims(xVal) ~= ndims(dImg), error('Mask must be logical and have same number of dimensions as the image!'); end
                        if any(size(dImg) ~= size(xVal)), error('Mask must have same size as image'); end
                        lMask = xVal;
                    case {'f', 'flow'}
                        if ndims(xVal)-1 ~= ndims(dImg) || all(size(xVal,ndims(xVal)) ~= [2,3]), error('Flow must be of the same dimensions as the image with last dimension being 2 or 3 [x,y,z,t1,t2,2/3]!'); end
                        if any([size(dImg),size(xVal,ndims(xVal))] ~= size(xVal)), error('Flow must have same size as image'); end
                        dFlow = xVal;
                    case {'p', 'panels'}
                        if ~isnumeric(xVal) || numel(xVal) ~= 2, error('Panel size must be a [2x1] or [1x2] numeric vector!'); end
                        SState.iPanels = xVal(:)';
                    case {'c', 'colormap'}
                        if ~isnumeric(xVal) || size(xVal,2) ~=3, error('Colormap must be [nx3] numeric array!'); end
                        SState.dColormapBack = xVal;
                        colormap(xVal);
                    case {'r', 'record'}
                        if ~ischar(xVal), error('CSV file must be specified as string'); end
                        SState.sEvalFilename = xVal;
                        sPath = fileparts(xVal);
                        SState.sPath = sPath;
                    otherwise, error('Unknown property ''%s''!', xInput);
                end
                    
            end
            iInd = iInd + 1;
        end
        if iDataInd, fAddImageToData(dImg, sName, 'startup', dDim, sUnits, dWindow, lMask, dFlow, sOri); end

        if sum(SState.iPanels) == 0
            iNumImages = length(SData);
            dRoot = sqrt(iNumImages);
            iPanelsN = ceil(dRoot);
            iPanelsM = ceil(dRoot);
            while iPanelsN*iPanelsM >= iNumImages
                iPanelsN = iPanelsN - 1;
            end
            iPanelsN = iPanelsN + 1;
            iPanelsN = min([4, iPanelsN]);
            iPanelsM = min([4, iPanelsM]);
            SState.iPanels = [iPanelsN, iPanelsM];
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fParseInputs
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fLoadFiles (nested in imagine)
    % * * 
    % * * Load image files from disk and sort into series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =    
    function fLoadFiles(csFilenames)
        if ~iscell(csFilenames), csFilenames = {csFilenames}; end % If only one file
        lLoaded = false(length(csFilenames), 1);
        
        SImageData = [];
        hW = waitbar(0, 'Loading files');
        for i = 1:length(csFilenames)
            [sPath, sName, sExt] = fileparts(csFilenames{i}); %#ok<ASGLU>
            switch lower(sExt)
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Standard image data: Try to group according to size
                case {'.jpg', '.jpeg', '.tif', '.tiff', '.gif', '.bmp', '.png'}
                    try
                        dImg = double(imread([SState.sPath, csFilenames{i}]))./255;
                        lLoaded(i) = true;
                    catch %#ok<CTCH>
                        disp(['Error when loading "', SState.sPath, csFilenames{i}, '": File extenstion and type do not match']);
                        continue;
                    end
                    dImg = mean(dImg, 3);
                    iInd = fServesSizeCriterion(size(dImg), SImageData);
                    if iInd
                        dImg = cat(3, SImageData(iInd).dImg, dImg);
                        SImageData(iInd).dImg = dImg;
                    else
                        iLength = length(SImageData) + 1;
                        SImageData(iLength).dImg = dImg;
                        SImageData(iLength).sOrigin = 'Image File';
                        SImageData(iLength).sName = csFilenames{i};
                        SImageData(iLength).dPixelSpacing = [1 1 1];
                    end
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % NifTy Data
                case '.nii'
                    set(hF, 'Pointer', 'watch'); drawnow;
                    [dImg, dDim] = fNifTyRead([SState.sPath, csFilenames{i}]);
                    if ndims(dImg) > 4, error('Only 4D data supported'); end
                    lLoaded(i) = true;
                    fAddImageToData(dImg, csFilenames{i}, 'NifTy File', dDim, 'mm');
                    set(hF, 'Pointer', 'arrow');
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                case '.gipl'
                    set(hF, 'Pointer', 'watch'); drawnow;
                    [dImg, dDim] = fGIPLRead([SState.sPath, csFilenames{i}]);
                    lLoaded(i) = true;
                    fAddImageToData(dImg, csFilenames{i}, 'GIPL File', dDim, 'mm');
                    set(hF, 'Pointer', 'arrow');
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                case '.mat'
                    csVars = fMatRead([SState.sPath, csFilenames{i}]);
                    lLoaded(i) = true;
                    if isempty(csVars), continue, end   % Dialog aborted
                    
                    set(hF, 'Pointer', 'watch'); drawnow;
                    for iJ = 1:length(csVars)
                        S = load([SState.sPath, csFilenames{i}], csVars{iJ});
                        eval(['dImg = S.', csVars{iJ}, ';']);
                        fAddImageToData(dImg, sprintf('%s in %s', csVars{iJ}, csFilenames{i}), 'MAT File');
                    end
                    set(hF, 'Pointer', 'arrow');
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            end
            waitbar(i/length(csFilenames), hW);
        end
        close(hW);
        
        for i = 1:length(SImageData)
            fAddImageToData(SImageData(i).dImg, SImageData.sName, 'Image File', [1 1 1]);
        end
        
        set(hF, 'Pointer', 'watch'); drawnow;
        SDicomData = fDICOMRead(csFilenames(~lLoaded), SState.sPath);
        for i = 1:length(SDicomData)
            fAddImageToData(SDicomData(i).dImg, SDicomData(i).SeriesDescriptions, 'DICOM', SDicomData(i).Aspect, 'mm');
        end
        set(hF, 'Pointer', 'arrow');
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fLoadFiles
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fAddImageToData (nested in imagine)
    % * *
    % * * Add image data to the global SDATA variable. Can handle 2D, 3D or
    % * * 4D data.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fAddImageToData(dImage, sName, sOrigin, dDim, sUnits, dWindow, lMask, dFlow, sOri)
        if nargin < 9, sOri = 'RLHFAP'; end
        if nargin < 8, dFlow = []; end
        if nargin < 7, lMask = []; end
        if nargin < 6, dWindow = []; end
        if nargin < 5, sUnits = 'px'; end
        if nargin < 4, dDim = [1 1 1]; end
        if islogical(dImage), dImage = ones(size(dImage)).*dImage; end
        dImage = double(dImage);
        dImage(isnan(dImage)) = 0;
        iInd = length(SData) + 1;
        nDim = ndims(dImage);
        
        iGroupIndex = 1;
        if ~isempty(SData)
            iExistingGroups = unique([SData.iGroupIndex]);
            if ~isempty(iExistingGroups)
                while nnz(iExistingGroups == iGroupIndex), iGroupIndex = iGroupIndex + 1; end
            end
        end
        
        if(nDim >= 4)  % TK: change to nDim > 4 for old imagine behaviour with 4th dim
            if(nDim > 5)
                SData(iInd).dImgAll = dImage(:,:,:,:,:,1);
            else
                SData(iInd).dImgAll = dImage;
            end
            SData(iInd).dImg = dImage(:,:,:,1,1);
            if ~isempty(dWindow)
                dMin = dWindow(1);
                dMax = dWindow(2);
            else
                if isreal(SData(iInd).dImg)
                    dMin = min(SData(iInd).dImg(:));
                    dMax = max(SData(iInd).dImg(:));
                else
                    dMin = min(abs(SData(iInd).dImg(:)));
                    dMax = max(abs(SData(iInd).dImg(:)));
                end
            end
            SData(iInd).dDynamicRange = [dMin, dMax];
            SData(iInd).sOrigin = sOrigin;
            SData(iInd).dWindowCenter = (dMax + dMin)./2;
            SData(iInd).dWindowWidth  = dMax - dMin;
            SData(iInd).dZoomFactor = 1;
            SData(iInd).dDrawCenter = [0.5 0.5];
            SData(iInd).iActiveImage = 1;
            SData(iInd).iActiveND = [1 1];
            SData(iInd).lND = true;
            SData(iInd).lActive = false;
            if dDim(end) == 0, dDim(end) = min(dDim(1:2)); end
            SData(iInd).dPixelSpacing = dDim(:)';
            SData(iInd).sUnits = sUnits;
            SData(iInd).lMask = lMask;
            SData(iInd).dFlow = dFlow;
            SData(iInd).iMult = ones(1,3);
            SData(iInd).sOri = fGetOrientation(sOri, 'RLHFAP'); % orientation of x,y,z axis
            SData(iInd).iGroupIndex = iGroupIndex;
            SData(iInd).sEvalText = '';
            SData(iInd).sName = sName;
%             SData(iInd).sName = sprintf('%s [%02u/%02u, %02u/%02u]', sName, 1, size(dImage,4), 1, size(dImage,5));
%             iInd = iInd + 1;
        else
            for i = 1:size(dImage, 4)
                SData(iInd).dImg = dImage(:,:,:,i);
                if ~isempty(dWindow)
                    dMin = dWindow(1);
                    dMax = dWindow(2);
                else
                    if isreal(SData(iInd).dImg)
                        dMin = min(SData(iInd).dImg(:));
                        dMax = max(SData(iInd).dImg(:));
                    else
                        dMin = min(abs(SData(iInd).dImg(:)));
                        dMax = max(abs(SData(iInd).dImg(:)));
                    end
                end
                SData(iInd).dDynamicRange = [dMin, dMax];
                SData(iInd).sOrigin = sOrigin;
                SData(iInd).dWindowCenter = (dMax + dMin)./2;
                SData(iInd).dWindowWidth  = dMax - dMin;
                SData(iInd).dZoomFactor = 1;
                SData(iInd).dDrawCenter = [0.5 0.5];
                SData(iInd).iActiveImage = 1;
                SData(iInd).iActiveND = [1 1];
                SData(iInd).lND = false;
                SData(iInd).lActive = false;
                if dDim(end) == 0, dDim(end) = min(dDim(1:2)); end
                SData(iInd).dPixelSpacing = dDim(:)';
                SData(iInd).sUnits = sUnits;
                SData(iInd).lMask = lMask;
                if(size(dImage, 4) > 1)
                    if(size(dImage,3) > 1)
                        SData(iInd).dFlow = dFlow(:,:,:,i,:);
                    else
                        SData(iInd).dFlow = dFlow(:,:,i,:);
                    end
                else
                    SData(iInd).dFlow = dFlow;
                end
                SData(iInd).iMult = ones(1,3);
                SData(iInd).sOri = fGetOrientation(sOri, 'RLHFAP');
                SData(iInd).iGroupIndex = iGroupIndex;
                SData(iInd).sEvalText = '';
                if ndims(dImage) > 3
                    SData(iInd).sName = sprintf('%s_%02u', sName, i);
                else
                    SData(iInd).sName = sName;
                end
                iInd = iInd + 1;
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fAddImageToData
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetPanel (nested in imagine)
    % * *
    % * * Determine the panelnumber under the mouse cursor. Returns 0 if
    % * * not over a panel at all.
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iPanelInd = fGetPanel()
        iCursorPos = get(hF, 'CurrentPoint');
        iPanelInd = uint8(0);
        for i = 1:min([length(SPanels.hImg), length(SData) - SState.iStartSeries + 1])
            dPos = get(SPanels.hImgFrame(i), 'Position');
            if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                    (iCursorPos(2) >= dPos(2) + SAp.iEVALBARHEIGHT) && (iCursorPos(2) < dPos(2) + dPos(4) - SAp.iTITLEBARHEIGHT - SAp.iCOLORBARHEIGHT))
                iPanelInd = uint8(i);
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetPanel
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fServesSizeCriterion (nested in imagine)
    % * *
    % * * Determines, whether the data structure contains an image series
    % * * with the same x- and y-dimensions as iSize
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iInd = fServesSizeCriterion(iSize, SNewData)
        iInd = 0;
        for i = 1:length(SNewData)
            if (iSize(1) == size(SNewData(i).dImg, 1)) && ...
                    (iSize(2) == size(SNewData(i).dImg, 2))
                iInd = i;
                return;
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fServesSizeCriterion
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fZoom (nested in imagine)
    % * *
    % * * Zoom images
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fZoom(iD, dPanelPos)
        for i = 1:length(SData)
            if (~fIsOn('link')) && i ~= (SMouse.iStartAxis + SState.iStartSeries - 1), continue, end % Skip if axes not linked and current figure not active
            
            iAxisInd = i - SState.iStartSeries + 1;
                        
            dZoomFactor = max([0.25, SMouse.dZoomFactor(i).*exp(SPref.dZOOMSENSITIVITY.*iD(2))]);
            dZoomFactor = min([dZoomFactor, 100]);
            
            dScale = SData(i).dPixelSpacing;
            dScale = dScale(2:-1:1)./min(dScale); % Smallest Entry scaled to 1
            
            dStaticCoordinate = SMouse.dAxesStartPos - 0.5;
            dStaticCoordinate(2) = size(SData(i).dImg, 1) - dStaticCoordinate(2);
            iFramePos = get(SPanels.hImgFrame(SMouse.iStartAxis), 'Position');
            dStaticPoint = SMouse.iStartPos - iFramePos(1:2);
            if SState.lShowEvalbar, dStaticPoint(2) = dStaticPoint(2) - SAp.iEVALBARHEIGHT; end;
            
            dStartPoint = dStaticPoint - (dStaticCoordinate).*dZoomFactor.*dScale + [1.5 1.5];
            dEndPoint   = dStaticPoint + ([size(SData(i).dImg, 2), size(SData(i).dImg, 1)] - dStaticCoordinate).*dZoomFactor.*dScale + [1.5 1.5];
            
            SData(i).dDrawCenter = (dEndPoint + dStartPoint)./(2.*dPanelPos(3:4)); % Save Draw Center
            SData(i).dZoomFactor = dZoomFactor; % Save ZoomFactor data
            
            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

            dScale = SData(i).dPixelSpacing;
            dScale = dScale./min(dScale); % Smallest Entry scaled to 1
                
            dImageWidth  = double(size(SData(i).dImg, 2)).*dZoomFactor.*dScale(2);
            dImageHeight = double(size(SData(i).dImg, 1)).*dZoomFactor.*dScale(1);
            set(SAxes.hImg(iAxisInd), 'Position', [dPanelPos(3).*SData(i).dDrawCenter(1) - dImageWidth/2, ...
                dPanelPos(4).*SData(i).dDrawCenter(2) - dImageHeight/2, ...
                dImageWidth, dImageHeight]);
            if iAxisInd == SMouse.iStartAxis % Show zooming information for the starting axis
                set(STexts.hStatus, 'String', sprintf('Zoom: %3.1fx', dZoomFactor));
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fZoom
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fWindow (nested in imagine)
    % * *
    % * * Window an image (that is radiology slang for
    % * * "adjust contrast and brightness")
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindow(iD)
        for i = 1:length(SData)
            if (~fIsOn('link')) && (i ~= SMouse.iStartAxis + SState.iStartSeries - 1), continue, end % Skip if axes not linked and current figure not active
            
            SData(i).dWindowWidth  = SMouse.dWindowWidth(i) .*exp(SPref.dWINDOWSENSITIVITY*(-iD(2)));
            SData(i).dWindowCenter = SMouse.dWindowCenter(i).*exp(SPref.dWINDOWSENSITIVITY*  iD(1));
            iAxisInd = i - SState.iStartSeries + 1;
            if iAxisInd < 1 || iAxisInd > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels)
            if iAxisInd == SMouse.iStartAxis % Show windowing information for the starting axes
                set(STexts.hStatus, 'String', sprintf('C: %s, W: %s', fPrintNumber(SData(i).dWindowCenter), fPrintNumber(SData(i).dWindowWidth)));
            end
        end
        fFillPanels;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindow
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fIsOn (nested in imagine)
    % * *
    % * * Determine whether togglebutton is active
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function lOn = fIsOn(sTag)
        lOn = SIcons(strcmp({SIcons.Name}, sTag)).Active;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIsOn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION SDataOut (nested in imagine)
    % * *
    % * * Thomas' hack function to get the data structure
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function SDataOut = fGetData
        SDataOut = SData;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION SDataOut
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fPrintNumber (nested in imagine3D)
    % * *
    % * * Display a value in adequate format
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function sString = fPrintNumber(xNumber)
        if ((abs(xNumber) < 0.01) && (xNumber ~= 0)) || (abs(xNumber) > 1E4)
            sString = sprintf('%2.1E', xNumber);
        else
            sString = sprintf('%4.2f', xNumber);
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fPrintNumber
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fBackgroundImg (nested in imagine)
    % * * 
    % * * Create a funky image for empty panels
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImg = fBackgroundImg(dHeight, dWidth)
        
        dLogo = [0 0 0 1 1 0 0 0; ...
                 0 0 0 1 1 0 0 0; ...
                 0 0 0 0 0 0 0 0; ...
                 0 0 1 1 1 0 0 0; ...
                 0 0 0 1 1 0 0 0; ...
                 0 0 0 1 1 0 0 0; ...
                 0 0 1 1 1 1 0 0; ...
                 0 0 0 0 0 0 0 0;];
             
        dWidth  = ceil(dWidth./16);
        dHeight = ceil(dHeight./16);
        dImg = 0.6 + 0.4.*rand(dHeight, dWidth);
        if ~any(size(dImg) < 8)
            dImg(floor(dHeight/2) - 3:floor(dHeight/2) + 4, floor(dWidth/2) - 3:floor(dWidth/2) + 4) = ...
            dImg(floor(dHeight/2) - 3:floor(dHeight/2) + 4, floor(dWidth/2) - 3:floor(dWidth/2) + 4) + 0.6.*dLogo;
        end

        dImg = fReplicate(dImg, 1);
        dImg = 0.9.*dImg + 0.1.*rand(size(dImg));
        dImg = fReplicate(dImg, 3);

        dImg = imfilter(dImg, [0 -3 0; -3 13 -3; 0 -3 0], 'circular', 'same');
        dImg = 0.8.*dImg + 0.7.*rand(size(dImg));
        dImg = dImg.*repmat(linspace(1, 0.3, size(dImg, 1))', [1, size(dImg, 2)]);

        dImg = repmat(dImg, [1 1 3]);
        dImg = dImg.*repmat(permute(SAp.dBGCOLOR./2, [1 3 2]) , [size(dImg, 1), size(dImg, 2), 1]);
        dImg(dImg > 1.0) = 1.0;
        dImg(dImg < 0.0) = 0.0;

    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fBackgroundImg
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
        
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fReplicate (nested in imagine)
    % * * 
    % * * Scale image by power of 2 by nearest neighbour interpolation
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImgOut = fReplicate(dImg, iIter)
        dImgOut = zeros(2.*size(dImg));
        dImgOut(1:2:end, 1:2:end) = dImg;
        dImgOut(2:2:end, 1:2:end) = dImg;
        dImgOut(1:2:end, 2:2:end) = dImg;
        dImgOut(2:2:end, 2:2:end) = dImg;
        iIter = iIter - 1;
        if iIter > 0, dImgOut = fReplicate(dImgOut, iIter); end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fReplicate
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fCompileMex (nested in imagine)
    % * * 
    % * * Scale image by power of 2 by nearest neighbour interpolation
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCompileMex
        fprintf('Imagine will try to compile some mex files!\n');
        sToolsPath = [SPref.sMFILEPATH, filesep, 'tools'];
        S = dir([sToolsPath, filesep, '*.cpp']);
        sPath = cd;
        cd(sToolsPath);
        lSucc = true;
        for i = 1:length(S)
            [temp, sName] = fileparts(S(i).name); %#ok<ASGLU>
            if exist(sName, 'file') == 3, continue, end
            try
                eval(['mex ', S(i).name]);
            catch
                warning('Could nor compile ''%s''!', S(i).name);
                lSucc = false;
            end
        end
        cd(sPath);
        if ~lSucc
            warndlg(sprintf('Not all mex files could be compiled, thus some tools will not be available. Try to setup the mex-compiler using ''mex -setup'' and compile the *.cpp files in the ''tools'' folder manually.'), 'IMAGINE');
        else
            fprintf('Hey, it worked!\n');
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCompileMex
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
end
% =========================================================================
% *** END FUNCTION imagine (and its nested functions)
% =========================================================================




% #########################################################################
% ***
% ***   Helper GUIS and their callbacks
% ***
% #########################################################################


% =========================================================================
% *** FUNCTION fGridSelect
% ***
% *** Creates a tiny GUI to select the GUI layout, i.e. the number of
% *** panels and the grid dimensions.
% ***
% =========================================================================
function iSizeOut = fGridSelect(iM, iN)

iAXESSIZE = 30;
iSizeOut = [0 0];

% -------------------------------------------------------------------------
% Create a new figure at the current mouse pointer position
iPos = get(0, 'PointerLocation');
iHeight = iAXESSIZE*iM;
iWidth  = iAXESSIZE*iN;
hGridFig = figure(...
    'Position'             , [iPos(1), iPos(2) - iHeight, iWidth, iHeight], ...
    'Units'                , 'pixels', ...
    'Color'                , [0.5 0.5 0.5], ...
    'DockControls'         , 'off', ...
    'WindowStyle'          , 'modal', ...
    'Name'                 , '', ...
    'WindowButtonMotionFcn', @fGridMouseMoveFcn, ...
    'WindowButtonDownFcn'  , 'uiresume(gcbf)', ... % continues the execution of this function after the uiwait when the mousebutton is pressed
    'NumberTitle'          , 'off', ...
    'Resize'               , 'off');

colormap gray
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create MxN axes/images for the visualization
hA = zeros(iM, iN);
hI = zeros(iM, iN);
for iI = 1:iM
    for iJ = 1:iN
        hA(iI, iJ) = axes(...
            'Units'     , 'pixels', ...
            'Position'  , [(iJ - 1)*iAXESSIZE + 2, (iM - iI)*iAXESSIZE + 2, iAXESSIZE-2, iAXESSIZE-2], ...
            'Parent'    , hGridFig, ...
            'Color'     , 'w', ...
            'XLim'      , [0.5 1.5], ...
            'YLim'      , [0.5 1.5]); %#ok<LAXES>
        
        hI(iI, iJ) = image(256.*ones(1), ...
            'Parent'        ,  hA(iI, iJ));
        
        axis(hA(iI, iJ), 'off');
    end
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Handle GUI interaction
uiwait(hGridFig); % Wait until the uiresume function is called (happens when mouse button is pressed, see creation of the figure above)
try % Button was pressed, return the amount of selected panels
    delete(hGridFig); % close the figure
catch %#ok<CTCH> % if figure could not be deleted (dialog aborted), return [0 0]
    iSizeOut = [0 0];
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGridMouseMoveFcn (nested in fGridSelect)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fGridMouseMoveFcn(hObject, eventdata)
        dCursorPos = get(hGridFig, 'CurrentPoint'); % The mouse pointer
        dPos       = get(hGridFig, 'Position');     % The figure dimensions

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Determine over which axes the mouse pointer is located
        i = ceil((dPos(4) - dCursorPos(2))/iAXESSIZE);
        j = ceil(dCursorPos(1)/iAXESSIZE);
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Update the axes's colors to visualize the current selection
        for n = 1:size(hA, 1)
            for m = 1:size(hA, 2)
                if (i >= n) && (j >= m)
                    set(hI(n, m), 'CData', 0);
                else
                    set(hI(n, m), 'CData', 256);
                end
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        iSizeOut = [i, j]; % Update output variable
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGridMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fGridSelect (and its nested functions)
% =========================================================================



% =========================================================================
% *** FUNCTION fColormapSelect
% ***
% *** Creates a tiny GUI to select the colormap.
% ***
% =========================================================================
function dColormap = fColormapSelect(hText)

iWIDTH = 128;
iBARHEIGHT = 32;

% -------------------------------------------------------------------------
% List the MATLAB built-in colormaps
csColormaps = {'gray', 'bone', 'copper', 'pink', 'hot', 'jet', 'hsv', 'cool'};
iNColormaps = length(csColormaps);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Add custom colormaps (if any)
sColormapPath = [fileparts(mfilename('fullpath')), filesep, 'colormaps'];
SDir = dir([sColormapPath, filesep, '*.m']);
for iI = 1:length(SDir)
    iNColormaps = iNColormaps + 1;
    [sPath, sName] = fileparts(SDir(iI).name); %#ok<ASGLU>
    csColormaps{iNColormaps} = sName;
end
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% Create a new figure at the current mouse pointer position
iPos = get(0, 'PointerLocation');
iHeight = iNColormaps.*iBARHEIGHT;
hColormapFig = figure(...
    'Position'             , [iPos(1), iPos(2) - iHeight, iWIDTH, iHeight], ...
    'WindowStyle'          , 'modal', ...
    'Name'                 , '', ...
    'WindowButtonMotionFcn', @fColormapMouseMoveFcn, ...
    'WindowButtonDownFcn'  , 'uiresume(gcbf)', ... % continues the execution of this function after the uiwait when the mousebutton is pressed
    'NumberTitle'          , 'off', ...
    'Resize'               , 'off');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Make the true-color image with the colormaps
dImg = zeros(iNColormaps, iWIDTH, 3);
dLine = zeros(iWIDTH, 3);
for iI = 1:iNColormaps
    eval(['dLine = ', csColormaps{iI}, '(iWIDTH);']);
    dImg(iI, :, :) = permute(dLine, [3, 1, 2]);
end

% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create axes and image for selection
hA = axes(...
    'Units'     , 'pixels', ...
    'Position'  , [1, 1, iWIDTH, iHeight], ...
    'Parent'    , hColormapFig, ...
    'Color'     , 'w', ...
    'XLim'      , [0.5 128.5], ...
    'YLim'      , [0.5 length(csColormaps) + 0.5]);

image(dImg, 'Parent',  hA);

axis(hA, 'off');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Handle GUI interaction
iLastInd = 0;
uiwait(hColormapFig); % Wait until the uiresume function is called (happens when mouse button is pressed, see creation of the figure above)

try % Button was pressed, return the amount of selected panels
    dPos = get(hA, 'CurrentPoint');
    iInd = round(dPos(1, 2));
    dColormap = zeros(256, 3);
    eval(['dColormap = ', csColormaps{iInd}, '(256);']);
    delete(hColormapFig); % close the figure
catch %#ok<CTCH> % if figure could not be deleted (dialog aborted), return [0 0]
    dColormap = [];
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fColormapMouseMoveFcn (nested in fColormapSelect)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fColormapMouseMoveFcn(hObject, eventdata)
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Determine over which colormap the mouse pointer is located
        dPos = get(hA, 'CurrentPoint');
        iInd = round(dPos(1, 2));
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Update the figure's colormap if desired
        if iInd ~= iLastInd
            set(hText, 'String', csColormaps{iInd});
            iLastInd = iInd;
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fColormapMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fColormapSelect (and its nested functions)
% =========================================================================


% =========================================================================
% *** FUNCTION fFlowSelect
% ***
% *** Creates a tiny GUI to select the settings for the flow.
% ***
% =========================================================================
function [iQuiverFlow, iStrengthFlow, dColorFlow] = fFlowSelect(hText, iQuiverFlow, iStrengthFlow, dColorFlow)

iWIDTH = 240;
iHeight = 160;
iBUTTONHEIGHT = 24;

% iQuiverFlow = 8;
% iStrengthFlow = 1;
% dColorFlow = [1 1 0];


% -------------------------------------------------------------------------
% Create a new figure at the current mouse pointer position
iPos = get(0, 'PointerLocation');
hFlowFig = figure(...
    'Position'             , [iPos(1), iPos(2) - iHeight, iWIDTH, iHeight], ...
    'WindowStyle'          , 'modal', ...
    'Name'                 , '', ...
    'Color'                , 'k', ...
    'NumberTitle'          , 'off', ...
    'Resize'               , 'off');

hButOK = uicontrol(hFlowFig, ...
    'Style'                 , 'pushbutton', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [1 1 iWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , 'OK');

uicontrol(hFlowFig, ...
    'Style'                 , 'pushbutton', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/2 + 1 1 iWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , 'uiresume(gcf);', ...
    'String'                , 'Cancel');

hButColor = uicontrol(hFlowFig, ...
    'Style'                 , 'pushbutton', ...
    'BackgroundColor'       , dColorFlow, ...
    'ForegroundColor'       , 'k', ...
    'Position'              , [iWIDTH/8 iHeight-iBUTTONHEIGHT-2 iWIDTH*3/4 iBUTTONHEIGHT], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , 'Change flow color');

try
hTextQuiver = uicontrol(hFlowFig, ...
    'Style'                 , 'Text', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-2*iBUTTONHEIGHT-10, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'InnerPosition'         , [iWIDTH/8, iHeight-2*iBUTTONHEIGHT-14, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'String'                , 'Flow distance [px]');
catch
    hTextQuiver = uicontrol(hFlowFig, ...
    'Style'                 , 'Text', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-2*iBUTTONHEIGHT-10, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'String'                , 'Flow distance [px]');
end

hEditQuiver = uicontrol(hFlowFig, ...
    'Style'                 , 'Edit', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH*5/8+10, iHeight-2*iBUTTONHEIGHT-10, iWIDTH*1/4-10, iBUTTONHEIGHT], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , num2str(iQuiverFlow));
    
hSliderQuiver = uicontrol(hFlowFig, ...
    'Style'                 , 'slider', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-3*iBUTTONHEIGHT-10, iWIDTH*3/4, iBUTTONHEIGHT], ...
    'Min'                   , 0, ...
    'Max'                   , 100, ...
    'Value'                 , iQuiverFlow, ...
    'SliderStep'            , [0.01 0.1], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , 'quiver distance');

try
hTextStrength = uicontrol(hFlowFig, ...
    'Style'                 , 'Text', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-4*iBUTTONHEIGHT-10, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'InnerPosition'         , [iWIDTH/8, iHeight-4*iBUTTONHEIGHT-14, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'String'                , 'Flow strength [%]');
catch
    hTextStrength = uicontrol(hFlowFig, ...
    'Style'                 , 'Text', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-4*iBUTTONHEIGHT-10, iWIDTH*1/2+10, iBUTTONHEIGHT], ...
    'String'                , 'Flow strength [%]');
end

hEditStrength = uicontrol(hFlowFig, ...
    'Style'                 , 'Edit', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH*5/8+10, iHeight-4*iBUTTONHEIGHT-10, iWIDTH*1/4-10, iBUTTONHEIGHT], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , num2str(iStrengthFlow));
    
hSliderStrength = uicontrol(hFlowFig, ...
    'Style'                 , 'slider', ...
    'BackgroundColor'       , 'k', ...
    'ForegroundColor'       , 'w', ...
    'Position'              , [iWIDTH/8, iHeight-5*iBUTTONHEIGHT-10, iWIDTH*3/4, iBUTTONHEIGHT], ...
    'Min'                   , 0, ...
    'Max'                   , 1000, ...
    'Value'                 , iStrengthFlow, ...
    'SliderStep'            , [0.01/10 0.1/10], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , 'quiver strength');
  
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set default action and enable gui interaction
sAction = 'Cancel';
uiwait(hFlowFig);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
if strcmp(sAction, 'OK')
    %     NOP
end
try %#ok<TRYNC>
    close(hFlowFig);
end
% -------------------------------------------------------------------------

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION SelectEvalCallback (nested in fSelectEvalFcns)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function SelectEvalCallback(hObject, eventdata)
        if isfield(eventdata, 'Key')
            switch eventdata.Key
                case 'escape', uiresume(hFlowFig);
                case 'return'
                    sAction = 'OK';
                    uiresume(hFlowFig);
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % React on action depending on its source component
        switch(hObject)
            
            case hButOK
                sAction = 'OK';
                uiresume(hFlowFig);
                
            case hButColor
                dColorFlow = uisetcolor(dColorFlow, 'Pick flow color');
                set(hButColor,'BackgroundColor', dColorFlow);
                
            case hSliderQuiver
                iQuiverFlowC = get(hSliderQuiver, 'Value');
                iQuiverFlow = round(iQuiverFlowC);
                set(hEditQuiver, 'String', num2str(iQuiverFlow));
                if(iQuiverFlowC ~= iQuiverFlow)
                    set(hSliderQuiver, 'Value', iQuiverFlow);
                end
                
            case hEditQuiver
                iQuiverFlow = str2double(get(hEditQuiver, 'String'));
                set(hSliderQuiver, 'Value', iQuiverFlow);
                
            case hSliderStrength
                iStrengthFlowC = get(hSliderStrength, 'Value');
                iStrengthFlow = round(iStrengthFlowC);
                set(hEditStrength, 'String', num2str(iStrengthFlow));
                if(iStrengthFlowC ~= iStrengthFlow)
                    set(hSliderStrength, 'Value', iStrengthFlow);
                end
                
            case hEditStrength
                iStrengthFlow = str2double(get(hEditStrength, 'String'));
                set(hSliderStrength, 'Value', iStrengthFlow);
                
            otherwise

        end
        % End of switch statement
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION SelectEvalCallback
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fFlowSelect (and its nested functions)
% =========================================================================


% =========================================================================
% *** FUNCTION fSelectEvalFcns
% ***
% *** Lets the user select the eval functions for evaluation
% ***
% =========================================================================
function csFcns = fSelectEvalFcns(csActive, sPath)

iFIGUREWIDTH = 300;
iFIGUREHEIGHT = 400;
iBUTTONHEIGHT = 24;

csFcns = 0;
iPos = get(0, 'ScreenSize');

SDir = dir([sPath, filesep, '*.m']);
lActive = false(length(SDir), 1);
csNames = cell(length(SDir), 1);
for iI = 1:length(SDir)
    csNames{iI} = SDir(iI).name(1:end-2);
    for iJ = 1:length(csActive);
        if strcmp(csNames{iI}, csActive{iJ}), lActive(iI) = true; end
    end
end

% -------------------------------------------------------------------------
% Create figure and GUI elements
hF = figure( ...
    'Position'              , [(iPos(3) - iFIGUREWIDTH)/2, (iPos(4) - iFIGUREHEIGHT)/2, iFIGUREWIDTH, iFIGUREHEIGHT], ...
    'WindowStyle'           , 'modal', ...
    'Name'                  , 'Select Eval Functions...', ...
    'NumberTitle'           , 'off', ...
    'KeyPressFcn'           , @SelectEvalCallback, ...
    'Resize'                , 'off');

hList = uicontrol(hF, ...
    'Style'                 , 'listbox', ...
    'Position'              , [1 iBUTTONHEIGHT + 1 iFIGUREWIDTH iFIGUREHEIGHT - iBUTTONHEIGHT], ...
    'String'                , csNames, ...
    'Min'                   , 0, ...
    'Max'                   , 2, ...
    'Value'                 , find(lActive), ...
    'KeyPressFcn'           , @SelectEvalCallback, ...
    'Callback'              , @SelectEvalCallback);

hButOK = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Position'              , [1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , @SelectEvalCallback, ...
    'String'                , 'OK');

uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Position'              , [iFIGUREWIDTH/2 + 1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , 'uiresume(gcf);', ...
    'String'                , 'Cancel');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set default action and enable gui interaction
sAction = 'Cancel';
uiwait(hF);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% uiresume was triggered (in fMouseActionFcn) -> return
if strcmp(sAction, 'OK')
    iList = get(hList, 'Value');
    csFcns = cell(length(iList), 1);
    for iI = 1:length(iList)
        csFcns(iI) = csNames(iList(iI));
    end
end
try %#ok<TRYNC>
    close(hF);
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION SelectEvalCallback (nested in fSelectEvalFcns)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function SelectEvalCallback(hObject, eventdata)
        if isfield(eventdata, 'Key')
            switch eventdata.Key
                case 'escape', uiresume(hF);
                case 'return'
                    sAction = 'OK';
                    uiresume(hF);
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % React on action depending on its source component
        switch(hObject)
            
            case hList
                if strcmp(get(hF, 'SelectionType'), 'open')
                    sAction = 'OK';
                    uiresume(hF);
                end

            case hButOK
                sAction = 'OK';
                uiresume(hF);

            otherwise

        end
        % End of switch statement
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION SelectEvalCallback
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
end
% =========================================================================
% *** END FUNCTION fSelectEvalFcns (and its nested functions)
% =========================================================================

function csVarOut = fWSImportSelection(csVars, sTitle)

iFIGUREWIDTH = 300;
iFIGUREHEIGHT = 400;
iBUTTONHEIGHT = 24;

csVarOut = {};
iPos = get(0, 'ScreenSize');

% -------------------------------------------------------------------------
% Create figure and GUI elements
hF = figure( ...
    'Position'              , [(iPos(3) - iFIGUREWIDTH)/2, (iPos(4) - iFIGUREHEIGHT)/2, iFIGUREWIDTH, iFIGUREHEIGHT], ...
    'Units'                 , 'pixels', ...
    'DockControls'          , 'off', ...
    'WindowStyle'           , 'modal', ...
    'Name'                  , sTitle, ...
    'NumberTitle'           , 'off', ...
    'KeyPressFcn'           , @fMouseActionFcn, ...
    'Resize'                , 'off');

% csVars = evalin('base', 'who');
hList = uicontrol(hF, ...
    'Style'                 , 'listbox', ...
    'Units'                 , 'pixels', ...
    'Position'              , [1 iBUTTONHEIGHT + 1 iFIGUREWIDTH iFIGUREHEIGHT - iBUTTONHEIGHT], ...
    'HitTest'               , 'on', ...
    'String'                , csVars, ...
    'Min'                   , 0, ...
    'Max'                   , 2, ...
    'KeyPressFcn'           , @fMouseActionFcn, ...
    'Callback'              , @fMouseActionFcn);

hButOK = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , @fMouseActionFcn, ...
    'HitTest'               , 'on', ...
    'String'                , 'OK');

hButCancel = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Units'                 , 'pixels', ...
    'Position'              , [iFIGUREWIDTH/2 + 1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , 'uiresume(gcf);', ...
    'HitTest'               , 'on', ...
    'String'                , 'Cancel');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set default action and enable gui interaction
sAction = 'Cancel';
uiwait(hF);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% uiresume was triggered (in fMouseActionFcn) -> return

if strcmp(sAction, 'OK')
    iList = get(hList, 'Value');
    csVarOut = cell(length(iList), 1);
    for iI = 1:length(iList)
        csVarOut(iI) = csVars(iList(iI));
    end
end
try
    close(hF);
catch %#ok<CTCH>
    csVarOut = {};
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fMouseActionFcn (nested in fGetWorkspaceVar)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMouseActionFcn(hObject, eventdata)
        if isfield(eventdata, 'Key')
            switch eventdata.Key
                case 'escape', uiresume(hF);
                case 'return'
                    sAction = 'OK';
                    uiresume(hF);
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % React on action depending on its source component
        switch(hObject)
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Click in LISBOX: return if double-clicked
            case hList
                if strcmp(get(hF, 'SelectionType'), 'open')
                    sAction = 'OK';
                    uiresume(hF);
                end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % OK button
            case hButOK
                sAction = 'OK';
                uiresume(hF);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            otherwise

        end
        % End of switch statement
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGridMouseMoveFcn
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
end
% =========================================================================
% *** END FUNCTION fWSImportSelection (and its nested functions)
% =========================================================================

