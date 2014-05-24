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

% Last Modified by GUIDE v2.5 21-May-2014 15:32:58

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

LoadEpiTools();

% UIWAIT makes EpiTools wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%set up app-data
setappdata(0  , 'hMainGui'    , gcf);
setappdata(gcf, 'data_specifics', 'none');
setappdata(gcf, 'icy_is_used', 0);
setappdata(gcf, 'icy_is_loaded', 0);
setappdata(gcf, 'icy_path', 'none');


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
