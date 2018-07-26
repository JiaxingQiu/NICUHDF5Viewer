function varargout = HelpGUI(varargin)
% HELPGUI MATLAB code for HelpGUI.fig
%      HELPGUI, by itself, creates a new HELPGUI or raises the existing
%      singleton*.
%
%      H = HELPGUI returns the handle to a new HELPGUI or the handle to
%      the existing singleton*.
%
%      HELPGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HELPGUI.M with the given input arguments.
%
%      HELPGUI('Property','Value',...) creates a new HELPGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HelpGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HelpGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HelpGUI

% Last Modified by GUIDE v2.5 25-Jul-2018 16:24:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HelpGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @HelpGUI_OutputFcn, ...
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


% --- Executes just before HelpGUI is made visible.
function HelpGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HelpGUI (see VARARGIN)

% Choose default command line output for HelpGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

CategoryNames = {'Loading a file'; 'To Display All of the Data in the File'; 'To Display Multiple Datasets at Once';'To Browse Through the Data';'Using QRS Detection to Compute Heart Rate';}

set(handles.HelpCategories,'string',CategoryNames)

% UIWAIT makes HelpGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = HelpGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in HelpCategories.
function HelpCategories_Callback(hObject, eventdata, handles)
% hObject    handle to HelpCategories (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns HelpCategories contents as cell array
%        contents{get(hObject,'Value')} returns selected item from HelpCategories


% --- Executes during object creation, after setting all properties.
function HelpCategories_CreateFcn(hObject, eventdata, handles)
% hObject    handle to HelpCategories (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
