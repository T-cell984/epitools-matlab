function varargout = ProjectionGUI(varargin)
% PROJECTIONGUI MATLAB code for ProjectionGUI.fig
%      PROJECTIONGUI, by itself, creates a new PROJECTIONGUI or raises the existing
%      singleton*.
%
%      H = PROJECTIONGUI returns the handle to a new PROJECTIONGUI or the handle to
%      the existing singleton*.
%
%      PROJECTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROJECTIONGUI.M with the given input arguments.
%
%      PROJECTIONGUI('Property','Value',...) creates a new PROJECTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ProjectionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ProjectionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ProjectionGUI

% Last Modified by GUIDE v2.5 10-Sep-2014 17:27:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ProjectionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ProjectionGUI_OutputFcn, ...
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
% --- Executes just before ProjectionGUI is made visible.
function ProjectionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ProjectionGUI (see VARARGIN)

% Choose default command line output for ProjectionGUI
handles.output = hObject;

setappdata(0  , 'hPrjGui', gcf);
setappdata(gcf, 'settings_objectname', varargin{1});
setappdata(gcf, 'settings_modulename', 'Projection');


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ProjectionGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

updateAndGather(handles);

function updateAndGather(handles)
hPrjGui = getappdata(0  , 'hPrjGui');
hMainGui = getappdata(0  , 'hMainGui');
stgObj  = getappdata(hPrjGui, 'settings_objectname');
module_name = getappdata(hPrjGui, 'settings_modulename');

gathered_data = gatherData(handles);
fieldgd = fields(gathered_data);

for i=1:numel(fieldgd)
    idx = fieldgd(i);
    if(isfield(stgObj.analysis_modules.(char(module_name)).settings,char(idx)) == 0)
        stgObj.AddSetting(module_name, char(idx), gathered_data.(char(idx)));
    else
        stgObj.ModifySetting(module_name, char(idx), gathered_data.(char(idx)));
    end
end
% Store settings in setting object
setappdata(hMainGui, 'settings_objectname', stgObj);
updateLegends(handles);

% Gather slider values set on the controls
function gathered_data = gatherData(handles)
    gathered_data.SmoothingRadius = get(handles.smoothing_slider,'value');
    gathered_data.SurfSmoothness1 = get(handles.surface1_slider,'value');
    gathered_data.SurfSmoothness2 = get(handles.surface2_slider,'value');
    gathered_data.ProjectionDepthThreshold = get(handles.depth_slider,'value');
% Valorise control legends 
function updateLegends(handles)
hPrjGui = getappdata(0  , 'hPrjGui');
stgObj  = getappdata(hPrjGui, 'settings_objectname');
module_name = getappdata(hPrjGui, 'settings_modulename');
    caption = sprintf('Smoothing Radius = %.2f', stgObj.analysis_modules.(char(module_name)).settings.SmoothingRadius);
    set(handles.smoothing_label, 'String', caption);
    caption = sprintf('Surface Smoothness 1 = %.0f', stgObj.analysis_modules.(char(module_name)).settings.SurfSmoothness1);
    set(handles.surface1_label, 'String', caption);
    caption = sprintf('Surface Smoothness 2 = %.0f', stgObj.analysis_modules.(char(module_name)).settings.SurfSmoothness2);
    set(handles.surface2_label, 'String', caption);
    caption = sprintf('Cutoff distance = %.2f', stgObj.analysis_modules.(char(module_name)).settings.ProjectionDepthThreshold);
    set(handles.depth_label, 'String', caption);
    
% --- Outputs from this function are returned to the command line.
function varargout = ProjectionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
% --- Executes on slider movement.
function smoothing_slider_Callback(hObject, eventdata, handles)
% hObject    handle to smoothing_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

updateAndGather(handles);
% --- Executes during object creation, after setting all properties.
function smoothing_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothing_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%set defaults
default_smoothing_radius = 1;
set(hObject, 'value', default_smoothing_radius);
% --- Executes on slider movement.
function surface1_slider_Callback(hObject, eventdata, handles)
% hObject    handle to surface1_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

updateAndGather(handles);
% --- Executes during object creation, after setting all properties.
function surface1_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to surface1_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

default_surface_smoothness_1 = 30;
set(hObject, 'value', default_surface_smoothness_1);
% --- Executes on slider movement.
function surface2_slider_Callback(hObject, eventdata, handles)
% hObject    handle to surface2_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
updateAndGather(handles);
% --- Executes during object creation, after setting all properties.
function surface2_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to surface2_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

default_surface_smoothness_2 = 20;
set(hObject, 'value', default_surface_smoothness_2);
% --- Executes on slider movement.
function depth_slider_Callback(hObject, eventdata, handles)
% hObject    handle to depth_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
updateAndGather(handles);
% --- Executes during object creation, after setting all properties.
function depth_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to depth_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
default_projection_depth_threshold = 1.2;
set(hObject, 'value', default_projection_depth_threshold);
% --- Executes on button press in start_projection.
function start_projection_Callback(hObject, eventdata, handles)
% hObject    handle to start_projection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
stgObj  = getappdata(hMainGui, 'settings_objectname');
%params.InspectResults = true;         % show fit or not
show_surfaces_fitting = get(handles.show_surface_checkbox,'value');
stgObj.AddSetting('Projection','InspectResults',show_surfaces_fitting);
%params.Parallel = true;               % Use parallelisation?
stgObj.AddSetting('Projection','Parallel',true);
% Save settings and store them in global variable
updateAndGather(handles);

projection_caller(stgObj);
%Projection(stgObj);

%close projection gui after execution
%hProjGui = getappdata(0,'hPrjGui');
delete(getappdata(0,'hPrjGui'));
% --- Executes on button press in show_surface_checkbox.
function show_surface_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to show_surface_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of show_surface_checkbox
% --- Executes on button press in help_button.
function help_button_Callback(hObject, eventdata, handles)
% hObject    handle to help_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web('http://imls-bg-arthemis.uzh.ch/epitools/?url=Analysis_Modules/00_projection/');
