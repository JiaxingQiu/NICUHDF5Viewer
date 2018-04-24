function varargout = HDF5Viewer_v1_0_0(varargin)
% HDF5VIEWER_V1_0_0 MATLAB code for HDF5Viewer_v1_0_0.fig
%
%      This viewer was developed by Amanda Edwards at the University of
%      Virginia with the help of code created by Doug Lake at the
%      University of Virginia. This graphical user interface allows users
%      to:
%
%      - View data from hdf5 files in a 20 minute time window
%      - View multiple datasets at once on non-overlapping axes
%      - Interactively zoom using the mouse
%      - If desired, overlay multiple signals by checking the 'overlay box'
%      - Scroll forward and backward in the file in 5 minute increments
%      - Run QRS detection on waveform data
%      - Allow the user to choose to show only high-priority datasets or
%      all datasets contained in the file by checking a box
%      - This code is designed to work with HDF5 files produced using
%      UFC_v1.0.0
%      
%      This code will be improved over time to add additional features.
%
%      HDF5VIEWER_V1_0_0, by itself, creates a new HDF5VIEWER_V1_0_0 or raises the existing
%      singleton*.
%
%      H = HDF5VIEWER_V1_0_0 returns the handle to a new HDF5VIEWER_V1_0_0 or the handle to
%      the existing singleton*.
%
%      HDF5VIEWER_V1_0_0('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HDF5VIEWER_V1_0_0.M with the given input arguments.
%
%      HDF5VIEWER_V1_0_0('Property','Value',...) creates a new HDF5VIEWER_V1_0_0 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HDF5Viewer_v1_0_0_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HDF5Viewer_v1_0_0_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HDF5Viewer_v1_0_0

% Last Modified by GUIDE v2.5 17-Apr-2018 14:54:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HDF5Viewer_v1_0_0_OpeningFcn, ...
                   'gui_OutputFcn',  @HDF5Viewer_v1_0_0_OutputFcn, ...
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


% --- Executes just before HDF5Viewer_v1_0_0 is made visible.
function HDF5Viewer_v1_0_0_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HDF5Viewer_v1_0_0 (see VARARGIN)

% Choose default command line output for HDF5Viewer_v1_0_0
handles.output = hObject;
addpath('TabManager');
% Initialise tabs
handles.tabManager = TabManager( hObject );

% Set-up a selection changed function on the create tab groups
tabGroups = handles.tabManager.TabGroups;
for tgi=1:length(tabGroups)
    set(tabGroups(tgi),'SelectionChangedFcn',@tabChangedCB)
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes HDF5Viewer_v1_0_0 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Called when a user clicks on a tab
function tabChangedCB(src, eventdata)

disp(['Changing tab from ' eventdata.OldValue.Title ' to ' eventdata.NewValue.Title ] );


% --- Outputs from this function are returned to the command line.
function varargout = HDF5Viewer_v1_0_0_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in listbox_avail_signals.
function listbox_avail_signals_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_avail_signals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_avail_signals contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_avail_signals
contents = cellstr(get(hObject,'String'));
if isfield(handles,'overlayon')
    if handles.overlayon
%         handles.value{end+1} = contents{get(hObject,'Value')};
        handles.value = {contents{get(hObject,'Value')}};
    else
        handles.value = {contents{get(hObject,'Value')}};
    end
else
    handles.value = {contents{get(hObject,'Value')}};
end
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite);


function plotdata(hObject, eventdata, handles,overwrite)
numsigs = length(handles.value);
if isfield(handles,'overlayon')
    if handles.overlayon
        handles.numplots = 1;
    else
        handles.numplots = numsigs;
    end
else
    handles.numplots = numsigs;
end
handles.h = zeros(handles.numplots,1);
for s=1:numsigs
    [signame,varname,handles] = loadhdf5data(hObject, eventdata, handles,s);
    if isfield(handles,'overlayon')
        if handles.overlayon
            handles.h(s) = subplot(handles.numplots,1,1,'Parent',handles.PlotPanel);
            y1 = ylim;
        else
            handles.h(s) = subplot(numsigs,1,s,'Parent',handles.PlotPanel);
            y1 = ylim;
            ylim auto
        end
    else
        handles.h(s) = subplot(numsigs,1,s,'Parent',handles.PlotPanel);
        y1 = ylim;
        ylim auto
    end
    hold on
    [plotcolor] = customplotcolors(varname);
    if isfield(handles,'overlayon')
        if handles.overlayon
            y2 = ylim;
            ylim auto;
            y3 = ylim;
            ylimmin = min([y1(1),y2(1),y3(1)]);
            ylimmax = max([y1(2),y2(2),y3(2)]);
            ylim([ylimmin ylimmax]);
        end
    end
    % Clear the axes unless Overlay Checkbox is checked or unless we are
    % not on overwrite
    if isfield(handles,'overlayon')
        if ~handles.overlayon && overwrite
            cla;
        end
    else
        if overwrite
            cla;
        end
    end
    plot(handles.time,handles.sig,plotcolor);
    ylabel(signame);
    addpath('zoomAdaptiveDateTicks');
    zoomAdaptiveDateTicks('on')
    datetick('x',13)
    xlim([handles.windowstarttime handles.windowendtime])
end
linkaxes(handles.h,'x')
zoom on
% Update handles structure
guidata(hObject, handles);


function [plotcolor] = customplotcolors(varname)
plotcolor = 'k';
if contains(varname,'HR')
    plotcolor = 'r';
    ylim([0 250])
elseif contains(varname,'SPO2-%')
    plotcolor = 'b';
    ylim([0 100])
elseif contains(varname,'SPO2-R')
    plotcolor = 'm';
    ylim([0 250])
elseif contains(varname,'SpO2')
    plotcolor = 'b';
    ylim([0 100])
elseif contains(varname,'Waveforms/RR')
    plotcolor = 'g';
elseif contains(varname,'Waveforms/SPO2')
    plotcolor = 'b';
end


% --- Executes during object creation, after setting all properties.
function listbox_avail_signals_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_avail_signals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1: LOAD HDF5.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.filename, handles.pathname] = uigetfile('*.hdf5', 'Select an hdf5 file');
if isequal(handles.filename,0)
   disp('User selected Cancel')
else
   disp(['User selected ', fullfile(handles.pathname, handles.filename)])
end
handles.loadedfile.String = fullfile(handles.filename); % Show the name of the loaded file
handles.nextfiledisplay.String = '';
% Remove sampstart field from previous file
if isfield(handles,'sampstart')
    handles = rmfield(handles,'sampstart');
end
% Remove plots from previous signal
if isfield(handles,'h')
    for i=1:length(handles.h)
        cla(handles.h(i))
    end
end
readhdf5file(hObject, eventdata, handles);
handles = guidata(hObject);
set(handles.listbox_avail_signals,'string',handles.usefuldatasetnames);
guidata(hObject, handles);


% --- Executes on button press in ButtonTagNewEvent.
function ButtonTagNewEvent_Callback(hObject, eventdata, handles)
% hObject    handle to ButtonTagNewEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zoom off
brush on
fighandle = gcf;
bO = brush(fighandle);
% set(bO,'Enable','on');
% set(bO,'ActionPostCallback',@GetSelectedData);
% 
% function GetSelectedData
% hB = findobj(gcf,'-property','BrushData');
% data = get(hB,'BrushData');
% brushObj = hB(find(cellfun(@(x) sum(x),data)))


% --- Executes on selection change in AlgorithmSelectorPopUpMenu.
function AlgorithmSelectorPopUpMenu_Callback(hObject, eventdata, handles)
% hObject    handle to AlgorithmSelectorPopUpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AlgorithmSelectorPopUpMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AlgorithmSelectorPopUpMenu

contents = cellstr(get(hObject,'String')); %returns popupmenu1 contents as cell array
algchoice = contents{get(hObject,'Value')}; % returns selected item from popupmenu1
addpath('QRSDetection');
if strcmp(algchoice,'QRS Detection')
    callqrsdetection(hObject,eventdata,handles);
end


function callqrsdetection(hObject,eventdata,handles)
% run QRS detection on the selected signal with the designated lead, clear
% all current plots, and plot the results of the QRS detection in
% comparison to the heart rate plot
[hrt,hr,rrt,rr] = runQRSDetection2(handles,hObject,eventdata);
handles.h = subplot(1,1,1,'Parent',handles.PlotPanel);
cla
plot(hrt,hr,'.')
hold on
plot(rrt,rr,'.m')
addpath('zoomAdaptiveDateTicks');
ylim auto
zoomAdaptiveDateTicks('on')
datetick('x',13)
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function AlgorithmSelectorPopUpMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AlgorithmSelectorPopUpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
menuoptions = {'';'QRS Detection';'Another Algorithm';'Algorithm of your dreams'};
set(hObject,'String',menuoptions);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
handles = guidata(hObject);
if ~isfield(handles,'alldatasetnames')
%     findtimegroupanddatasetnames(hObject, eventdata, handles);
    readhdf5file(hObject,eventdata,handles);
end
handles = guidata(hObject);
if get(hObject,'Value')
    for i=1:length(handles.alldatasetnames)
        set(handles.listbox_avail_signals,'string',handles.alldatasetnames);
    end
else
    for i=1:length(handles.usefuldatasetnames)
        set(handles.listbox_avail_signals,'string',handles.usefuldatasetnames);
    end
end


% --- Executes on button press in nextfilebutton.
function nextfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to nextfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If the user wants to move to the next file in the same directory, they
% click the Next File Button

% Save the current directory so we can get back here
masterfolder = pwd; 
% Go to the directory the user selected (we have to go here to use the dir command)
cd(handles.pathname); 
% Find all the hdf5 files in this directory
hdf5files = dir('*.hdf5'); 
filenames = strings(length(hdf5files),1);
% Store the filenames as strings
for i=1:length(hdf5files) 
    filenames(i) = string(hdf5files(i).name);
end
% Sort the filenames so we are always looking at them in the same order regardless of what order the computer grabs them
if length(hdf5files)>1 
    filenames = sort(filenames);
end
% Find which file in the directory we are currently looking at
fileindex = find(filenames==handles.filename); 
if length(hdf5files)>fileindex 
    % If there are more files in the directory, get the name of the next file
    handles.filename = char(filenames(fileindex+1));
    % Update handles structure
    guidata(hObject, handles);
else
     % If there aren't any more files in the directory, tell the user that there are no more files
    handles.nextfiledisplay.String = 'No more files to display';
end
% Return back to the original folder
cd(masterfolder); 
% Remove plots from previous signal
if isfield(handles,'h')
    for i=1:length(handles.h)
        cla(handles.h(i))
    end
end
% Remove the sampstart field from the file
handles = rmfield(handles,'sampstart');
% Read the data from the next file in the folder
readhdf5file(hObject, eventdata, handles); 
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in OverlayCheckbox.
function OverlayCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to OverlayCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OverlayCheckbox
state = get(hObject,'Value');
handles.overlayon = state;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in forward_slow.
function forward_slow_Callback(hObject, eventdata, handles)
% hObject    handle to forward_slow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
jumptime = 5*60; % seconds to jump forward
handles.sampstart = handles.sampstart+jumptime;
handles.sampend = handles.sampend+jumptime;
if handles.totalsamples < handles.sampend
    if handles.totalsamples<handles.numsamps
        handles.sampstart = 1;
    else
        handles.sampstart = handles.totalsamples-handles.numsamps;
    end
    handles.sampend = handles.totalsamples;
end
handles.windowstarttime = addtodate(handles.windowstarttime,jumptime,'second');
handles.windowendtime = addtodate(handles.windowendtime,jumptime,'second');
overwrite = 0;
plotdata(hObject, eventdata, handles, overwrite)

% --- Executes on button press in backward_slow.
function backward_slow_Callback(hObject, eventdata, handles)
% hObject    handle to backward_slow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
jumptime = 5*60; % seconds to jump forward
handles.sampstart = handles.sampstart-jumptime;
handles.sampend = handles.sampend-jumptime;
if handles.sampstart<0
    handles.sampstart = 1;
    if handles.sampend>handles.totalsamples
        handles.sampend = handles.totalsamples;
    else
        handles.sampend = handles.numsamps;
    end
end
handles.windowstarttime = addtodate(handles.windowstarttime,-jumptime,'second');
handles.windowendtime = addtodate(handles.windowendtime,-jumptime,'second');
overwrite = 0;
plotdata(hObject, eventdata, handles, overwrite)
