function varargout = SkeletonConversionGUI(varargin)
% SKELETONCONVERSIONGUI MATLAB code for SkeletonConversionGUI.fig
%      SKELETONCONVERSIONGUI, by itself, creates a new SKELETONCONVERSIONGUI or raises the existing
%      singleton*.
%
%      H = SKELETONCONVERSIONGUI returns the handle to a new SKELETONCONVERSIONGUI or the handle to
%      the existing singleton*.
%
%      SKELETONCONVERSIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SKELETONCONVERSIONGUI.M with the given input arguments.
%
%      SKELETONCONVERSIONGUI('Property','Value',...) creates a new SKELETONCONVERSIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SkeletonConversionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SkeletonConversionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SkeletonConversionGUI

% Last Modified by GUIDE v2.5 10-Sep-2014 18:06:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SkeletonConversionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SkeletonConversionGUI_OutputFcn, ...
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


% --- Executes just before SkeletonConversionGUI is made visible.
function SkeletonConversionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SkeletonConversionGUI (see VARARGIN)

% Choose default command line output for SkeletonConversionGUI
handles.output = hObject;


setappdata(0  , 'hSkeletonGui', gcf);
setappdata(gcf, 'settings_objectname', varargin{1});
setappdata(gcf, 'settings_modulename', 'Skeletons');


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SkeletonConversionGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SkeletonConversionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in run_skeleton_conversion.
function run_skeleton_conversion_Callback(hObject, eventdata, handles)
% hObject    handle to run_skeleton_conversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hSkeletonGui = getappdata(0, 'hSkeletonGui');
stgObj  = getappdata(hSkeletonGui, 'settings_objectname');
strModuleName = getappdata(hSkeletonGui, 'settings_modulename');

use_polygon_crop = get(handles.use_polygon_crop,'value');
use_corrected_segmentation = get(handles.use_corrected_segmentation,'value');

stgObj.AddSetting(strModuleName,'use_polygon_crop',use_polygon_crop);
stgObj.AddSetting(strModuleName,'use_corrected_segmentation',use_corrected_segmentation);

SkeletonConversion(stgObj);

%Close after completion
delete(hSkeletonGui);


% --- Executes on button press in use_polygon_crop.
function use_polygon_crop_Callback(hObject, eventdata, handles)
% hObject    handle to use_polygon_crop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_polygon_crop


% --- Executes on button press in use_corrected_segmentation.
function use_corrected_segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to use_corrected_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_corrected_segmentation


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web('http://imls-bg-arthemis.uzh.ch/epitools/?url=Analysis%20Modules/05_skeleton/');