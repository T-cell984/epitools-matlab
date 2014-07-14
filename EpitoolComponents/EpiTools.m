function varargout = EpiTools(varargin)
% EPITOOLS MATLAB code for EpiTools.fig
%      EPITOOLS, by itself, creates a new EPITOOLS or raises the existing
%      singleton*.
%
%      H = EPITOOLS returns the handle to a new EPITOOLS or the handle to
%      the existing singleton*.
%
%      EPITOOLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EPITOOLS.M with the given input arguments.
%
%      EPITOOLS('Property','Value',...) creates a new EPITOOLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EpiTools_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EpiTools_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EpiTools

% Last Modified by GUIDE v2.5 14-Jul-2014 12:01:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EpiTools_OpeningFcn, ...
                   'gui_OutputFcn',  @EpiTools_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before EpiTools is made visible.
function EpiTools_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EpiTools (see VARARGIN)

% Choose default command line output for EpiTools
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%LoadEpiTools();

% UIWAIT makes EpiTools wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%set up app-data
setappdata(0  , 'hMainGui'    , gcf);
setappdata(gcf, 'data_specifics', 'none');
setappdata(gcf, 'icy_is_used', 0);
setappdata(gcf, 'icy_is_loaded', 0);
setappdata(gcf, 'icy_path', 'none');
setappdata(gcf, 'settings_objectname', '');

%obtain absolute location on system
current_script_path = mfilename('fullpath');
[file_path,~,~] = fileparts(current_script_path);
setappdata(gcf, 'settings_rootpath', file_path);

%% Find setting file in the arguments passed to calling function

intSettingsFound = 0;

if(size(varargin,2)>=1)
    for i=1:size(varargin,2)
        
        if(isa(varargin{i},'settings'))
            LoadControls(hObject, varargin{i});
            intSettingsFound = 1;
        end
        
    end
end
    
if (intSettingsFound == 0)

    varargin{(size(varargin,2)+1)} = settings('IMLS', 'TEST01', 1, 0.1,'','');
    
end


%set(handles.text8, 'String',varargin{1}.analysis_name)



% --- Outputs from this function are returned to the command line.
function varargout = EpiTools_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in set_data_button.
function set_data_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_data_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_folder = uigetdir('~/','Select the directory of the images to analyze');

if(data_folder ~= 0)
    if(exist(data_folder,'dir'))
        data_specifics = InspectData(data_folder);
        setappdata(hMainGui, 'data_specifics', data_specifics);
    end  
end




% --- Executes on button press in do_projection.
function do_projection_Callback(hObject, eventdata, handles)
% hObject    handle to do_projection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');
icy_is_used = getappdata(hMainGui,'icy_is_used');

if(~strcmp(data_specifics,'none'))
    
    %TODO check whether Proj is already present otherwise start Projection
    %with relative GUI
    load(data_specifics);
    projection_file = [AnaDirec,'/ProjIm'];
    if(exist([projection_file,'.mat'],'file'))
        do_overwrite = questdlg('Found previous result','GUI decision',...
    'Open GUI anyway','Show Result','Show Result');
        if(strcmp(do_overwrite,'Open GUI anyway'))
            ProjectionGUI;
        else
            load(projection_file);
            if(icy_is_used)
                try
                icy_vidshow(ProjIm,'Projected data');
                catch
                    errordlg('No icy instance found! Please open icy','No icy error');
                end
            else
                StackView(ProjIm);
            end
        end
    else
        ProjectionGUI;
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end

% --- Executes on button press in do_registration.
function do_registration_Callback(hObject, eventdata, handles)
% hObject    handle to do_registration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');

if(~strcmp(data_specifics,'none'))
    
    load(data_specifics);
    registration_file = [AnaDirec,'/RegIm'];
    if(exist([registration_file,'.mat'],'file'))
        do_overwrite = questdlg('Found previous result','GUI decision',...
    'Open GUI anyway','Show Result','Show Result');
        if(strcmp(do_overwrite,'Open GUI anyway'))
            RegistrationGUI;
        else
            load(registration_file);
            StackView(RegIm);
        end
    else
        RegistrationGUI;
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end



% --- Executes on button press in do_segmentation.
function do_segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to do_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');

if(~strcmp(data_specifics,'none'))
    
    load(data_specifics);
    segmentation_file = [AnaDirec,'/SegResults'];
    if(exist([segmentation_file,'.mat'],'file'))
        do_overwrite = questdlg('Found previous result','GUI decision',...
    'Open GUI anyway','Show Result','Show Result');
        if(strcmp(do_overwrite,'Open GUI anyway'))
            SegmentationGUI;
        else
            progressbar('Loading Segmentation file...');
            load(segmentation_file);
            progressbar(1);
            StackView(ColIms);
        end
    else
        SegmentationGUI;
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end


% --- Executes on button press in do_tracking.
function do_tracking_Callback(hObject, eventdata, handles)
% hObject    handle to do_tracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');

if(~strcmp(data_specifics,'none'))
    load(data_specifics);
    segmentation_file = [AnaDirec,'/SegResults'];
    if(exist([segmentation_file,'.mat'],'file'))
        TrackingIntroGUI;
    else
        errordlg('Please run the Segmentation first','No Segmentation Results found');
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end


% --- Executes on button press in do_skeletonConversion.
function do_skeletonConversion_Callback(hObject, eventdata, handles)
% hObject    handle to do_skeletonConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');

if(~strcmp(data_specifics,'none'))
    load(data_specifics);
    skeleton_files = [AnaDirec,'/skeletons'];
    if(exist(skeleton_files,'dir'))
        default_string = 'Show location';
        do_overwrite = questdlg('Found previous results','GUI decision',...
    'Open GUI anyway',default_string,default_string);
        if(strcmp(do_overwrite,default_string))
            uigetdir(skeleton_files,'This is where the skeletons are');
        else
            SkeletonConversionGUI;
        end
    else
        segmentation_file = [AnaDirec,'/SegResults'];
        if(exist([segmentation_file,'.mat'],'file'))
            SkeletonConversionGUI;
        else
            errordlg('Please run the Segmentation first','No Segmentation Results found');
        end
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end

% --- Executes on button press in enhance_contrast.
function enhance_contrast_Callback(hObject, eventdata, handles)
% hObject    handle to enhance_contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
data_specifics = getappdata(hMainGui,'data_specifics');

if(~strcmp(data_specifics,'none'))
    
    load(data_specifics);
    clahe_file = [AnaDirec,'/RegIm_woCLAHE'];
    if(exist([clahe_file,'.mat'],'file'))
        do_overwrite = questdlg('Found previous result','GUI decision',...
    'Open GUI anyway','Show Result','Show Result');
        if(strcmp(do_overwrite,'Open GUI anyway'))
            ImproveContrastGUI;
        else
            registration_file = [AnaDirec,'/RegIm'];
            load(registration_file);
            StackView(RegIm);
        end
    else
        ImproveContrastGUI;
    end
else
    helpdlg('Please select your Data Set first','No Data Set found');
end


% --- Executes on button press in use_icy_checkbox.
function use_icy_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to use_icy_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_icy_checkbox

hMainGui = getappdata(0, 'hMainGui');

if (get(hObject,'Value') == get(hObject,'Max'))
    %only enter when tick is activated
    
    %get app data
    icy_path =      getappdata(hMainGui,'icy_path');
    icy_is_loaded = getappdata(hMainGui,'icy_is_loaded');
    icy_is_used =   getappdata(hMainGui,'icy_is_used');
    
    %Check if icy's path was specified
    if(strcmp(icy_path,'none'))
        %user specification if none defined
        icy_path = uigetdir('~/','Please locate /path/to/Icy/plugins/ylemontag/matlabcommunicator');
        if(icy_path == 0) %user cancel
            icy_path = 'none';
        end
    end

    %Check if icy functions are already loaded
    if(~icy_is_loaded)
        if(exist([icy_path,'/icy_init.m'],'file'))
            fprintf('Successfully detected ICY at:%s\n',icy_path);
            addpath(icy_path);
            icy_init();
            icy_is_used = 1;
            icy_is_loaded = 1;
        else
            fprintf('ERROR, current icy path is not valid: %s\n',icy_path);
            icy_path = 'none';
        end
    else
        icy_is_used = 1;
    end
    
    %Check if icy is used
    if(icy_is_used ~= 1) 
        %do not check if icy_path was not set
        set(hObject,'Value',get(hObject,'Min'));
    end
    
    %set app data
    setappdata(hMainGui,'icy_path',icy_path);
    setappdata(hMainGui,'icy_is_loaded',icy_is_loaded);
    setappdata(hMainGui,'icy_is_used',icy_is_used);
    
else
    %checkbox is deselected
    setappdata(hMainGui,'icy_is_used',0);
end


% --- Executes during object creation, after setting all properties.
function use_icy_checkbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to use_icy_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --------------------------------------------------------------------
function MFile_Callback(hObject, eventdata, handles)
% hObject    handle to MFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMFile_Callback(hObject, eventdata, handles)
% hObject    handle to MMFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMAbout_Callback(hObject, eventdata, handles)
% hObject    handle to MMAbout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMFile_New_Callback(hObject, eventdata, handles)
% hObject    handle to MMFile_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMFile_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to MMFile_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMFile_Open_Callback(hObject, eventdata, handles)
% hObject    handle to MMFile_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
strSettingFilePath = uigetdfile('~/','Select the directory of the images to analyze');

if(strSettingFilePath ~= 0)

    load(strSettingFilePath, '-mat');
    varargin{(size(varargin,2)+1)} = stgObj;
    
end




% --------------------------------------------------------------------
function MmFile_Save_Callback(hObject, eventdata, handles)
% hObject    handle to MmFile_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MMFile_Close_Callback(hObject, eventdata, handles)
% hObject    handle to MMFile_Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MActions_Callback(hObject, eventdata, handles)
% hObject    handle to MActions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_Proj_Callback(hObject, eventdata, handles)
% hObject    handle to A_Proj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_StackReg_Callback(hObject, eventdata, handles)
% hObject    handle to A_StackReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_CLAHE_Callback(hObject, eventdata, handles)
% hObject    handle to A_CLAHE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_Segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to A_Segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_Tracking_Callback(hObject, eventdata, handles)
% hObject    handle to A_Tracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function A_Skeletons_Callback(hObject, eventdata, handles)
% hObject    handle to A_Skeletons (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function F_New_Callback(hObject, eventdata, handles)
% hObject    handle to F_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function F_Open_Callback(hObject, eventdata, handles)
% hObject    handle to F_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMainGui = getappdata(0, 'hMainGui');
strRootPath = getappdata(hMainGui,'settings_rootpath');

copyfile(fullfile(strRootPath,...
         'images','emblem-notice.png'));
[icoInformation] = imread('emblem-notice.png'); 
strSettingFilePath = uigetfile('.etl','Select analysis file');


if(strSettingFilePath ~= 0)

    load(strSettingFilePath, '-mat');
    setappdata(hMainGui, 'settings_objectname', stgObj);
    
    h = msgbox(sprintf('==================== Loading analysis ==================== \nName: %s  \nVersion: %s \nAuthor: %s \n======================================================\n\ncompleted with success!',...
        stgObj.analysis_name,stgObj.analysis_version,stgObj.user_name ),... 
        'Operation succesfully completed','custom',icoInformation);
    
end

%% Handles 
set(handles.mainTextBoxImagePath,'string',stgObj.data_imagepath);
set(handles.mainTextBoxSettingPath,'string',stgObj.data_fullpath);




% --------------------------------------------------------------------
function F_ImportSettings_Callback(hObject, eventdata, handles)
% hObject    handle to F_ImportSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function E_Undo_Callback(hObject, eventdata, handles)
% hObject    handle to E_Undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function E_Redo_Callback(hObject, eventdata, handles)
% hObject    handle to E_Redo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function E_Preferences_Callback(hObject, eventdata, handles)
% hObject    handle to E_Preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function F_Save_Callback(hObject, eventdata, handles)
% hObject    handle to F_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function F_Exit_Callback(hObject, eventdata, handles)
% hObject    handle to F_Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MHelp_Callback(hObject, eventdata, handles)
% hObject    handle to MHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MCredits_Callback(hObject, eventdata, handles)
% hObject    handle to MCredits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function mainTextBoxImagePath_Callback(hObject, eventdata, handles)
% hObject    handle to mainTextBoxImagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mainTextBoxImagePath as text
%        str2double(get(hObject,'String')) returns contents of mainTextBoxImagePath as a double


% --- Executes during object creation, after setting all properties.
function mainTextBoxImagePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainTextBoxImagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function mainTextBoxSettingPath_Callback(hObject, eventdata, handles)
% hObject    handle to mainTextBoxSettingPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mainTextBoxSettingPath as text
%        str2double(get(hObject,'String')) returns contents of mainTextBoxSettingPath as a double


% --- Executes during object creation, after setting all properties.
function mainTextBoxSettingPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainTextBoxSettingPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
