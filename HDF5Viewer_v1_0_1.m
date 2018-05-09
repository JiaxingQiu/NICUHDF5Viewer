function varargout = HDF5Viewer_v1_0_1(varargin)
% HDF5VIEWER_V1_0_1 MATLAB code for HDF5Viewer_v1_0_1.fig
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
%      - Scroll forward and backward in the file in 5/10 minute increments
%      - Run QRS detection on waveform data
%      - Allow the user to choose to show only high-priority datasets or
%      all datasets contained in the file by checking a box
%      - This code is designed to work with HDF5 files produced using
%      UFC_v1.0.1
%      
%      This code will be improved over time to add additional features.
%
%      HDF5VIEWER_V1_0_1, by itself, creates a new HDF5VIEWER_V1_0_1 or raises the existing
%      singleton*.
%
%      H = HDF5VIEWER_V1_0_1 returns the handle to a new HDF5VIEWER_V1_0_1 or the handle to
%      the existing singleton*.
%
%      HDF5VIEWER_V1_0_1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HDF5VIEWER_V1_0_1.M with the given input arguments.
%
%      HDF5VIEWER_V1_0_1('Property','Value',...) creates a new HDF5VIEWER_V1_0_1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HDF5Viewer_v1_0_1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HDF5Viewer_v1_0_1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HDF5Viewer_v1_0_1

% Last Modified by GUIDE v2.5 03-May-2018 14:32:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HDF5Viewer_v1_0_1_OpeningFcn, ...
                   'gui_OutputFcn',  @HDF5Viewer_v1_0_1_OutputFcn, ...
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


% --- Executes just before HDF5Viewer_v1_0_1 is made visible.
function HDF5Viewer_v1_0_1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HDF5Viewer_v1_0_1 (see VARARGIN)

% Choose default command line output for HDF5Viewer_v1_0_1
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

% UIWAIT makes HDF5Viewer_v1_0_1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Called when a user clicks on a tab
function tabChangedCB(src, eventdata)

disp(['Changing tab from ' eventdata.OldValue.Title ' to ' eventdata.NewValue.Title ] );


% --- Outputs from this function are returned to the command line.
function varargout = HDF5Viewer_v1_0_1_OutputFcn(hObject, eventdata, handles) 
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
        handles.value = {contents{get(hObject,'Value')}};
%         handles.value = get(hObject,'Value');
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
    varname = handles.value{1,s};
    handles.fs = double(h5readatt(fullfile(handles.pathname, handles.filename),varname,'Sample Frequency (Hz)'));
    handles.unitofmeasure = cellstr(h5readatt(fullfile(handles.pathname, handles.filename),varname,'Unit of Measure'));
    handles.scale = double(h5readatt(fullfile(handles.pathname, handles.filename),[varname '/data'],'Scale'));
    % For Philips IX monitors, the waveform sampling frequency is listed as either 4,8, or 16, but it should be 256.
    if handles.fs <=16
        if contains(varname,'Waveform')
            handles.fs = 256;
        end
    end
    handles.dataindex = find(ismember(handles.alldatasetnames,varname));
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
    handles.windowsize = 20*60*1000; % 20 min in milliseconds
    if ~isfield(handles,'startindex')
        handles.startindex = 1;
    end
    if handles.dataindex<=length(handles.vname) % Vital Signs
        handles.windowstarttime = handles.vt(handles.startindex);
        handles.windowendtime = handles.windowstarttime+handles.windowsize; % 20 min from start time in utc in ms
        [~,handles.endindex] = min(abs(handles.vt-handles.windowendtime));
        handles.sig = handles.vdata(handles.startindex:handles.endindex,handles.dataindex);
        handles.utctime = handles.vt(handles.startindex:handles.endindex);
        handles.localtime = utc2local(handles.utctime/1000);
%         handles.sig(handles.sig==-32768) = NaN;
        I = ~isnan(handles.sig); % Don't try to plot the NaN values
        plot(handles.localtime(I),handles.sig(I)/handles.scale,plotcolor);
    else % Waveforms
        handles.windowstarttime = handles.wt(handles.startindex);
        handles.windowendtime = handles.windowstarttime+handles.windowsize; % 20 min from start time in utc in ms
        [~,handles.endindex] = min(abs(handles.wt-handles.windowendtime));
        handles.sig = handles.wdata(handles.startindex:handles.endindex,handles.dataindex-length(handles.vname));
        handles.utctime = handles.wt(handles.startindex:handles.endindex);
        handles.localtime = utc2local(handles.utctime/1000);
%         handles.sig(handles.sig==-32768) = NaN;
        I = ~isnan(handles.sig); % Don't try to plot the NaN values
        plot(handles.localtime(I),handles.sig(I)/handles.scale,plotcolor);
    end
    ylabel(varname);
    addpath('zoomAdaptiveDateTicks');
    zoomAdaptiveDateTicks('on')
    datetick('x',13)
    xlim([utc2local(handles.windowstarttime/1000) utc2local(handles.windowendtime/1000)])
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
    plotcolor = 'g.';
elseif contains(varname,'Waveforms/SPO2')
    plotcolor = 'b.';
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
handles.nomorefiles = 0;
loaddata(hObject, eventdata, handles);


% This is where the data is actually loaded in - the money code!!
function loaddata(hObject, eventdata, handles)
% Let the user know the GUI is currently working on loading the data
set(handles.loadedfile,'string','Loading...');
waitfor(handles.loadedfile,'string','Loading...');
handles.nextfiledisplay.String = '';
% Remove startindex field from previous file
if isfield(handles,'startindex')
    handles = rmfield(handles,'startindex');
end
% Remove plots from previous signal
if isfield(handles,'h')
    for i=1:length(handles.h)
        cla(handles.h(i))
    end
end
% Load data from HDF5 File
[handles.vdata,handles.vname,handles.vt,~]=gethdf5vital(fullfile(handles.pathname, handles.filename));
[handles.wdata,handles.wname,handles.wt,~]=gethdf5wave(fullfile(handles.pathname, handles.filename));
handles.alldatasetnames = vertcat(handles.vname,handles.wname);
% Show only the most useful signals as a default
usefulfields = ["HR","SPO2-%","SPO2-R","Waveforms/I","Waveforms/II","Waveforms/III","Waveforms/RR","Waveforms/SPO2"];
usefulfieldindices = contains(handles.alldatasetnames,usefulfields);
handles.usefuldatasetnames = handles.alldatasetnames(usefulfieldindices);
set(handles.listbox_avail_signals,'string',handles.usefuldatasetnames);
handles.loadedfile.String = fullfile(handles.filename); % Show the name of the loaded file
set(handles.listbox_avail_signals, 'Value', []); % This removes the selection highlighting from the listbox (this is important in case, for example, you have selected item 8 and then you load another file with only 5 items)
% Update handles structure
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
[hrt,hr,rrt,rr] = runQRSDetection2(hObject,eventdata,handles);
handles.h = subplot(1,1,1,'Parent',handles.PlotPanel);
cla
if ~isempty(hr)
    plot(hrt,hr,'.')
end
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


% --- Executes on button press in show_all_avail_fields_checkbox.
function show_all_avail_fields_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to show_all_avail_fields_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_all_avail_fields_checkbox
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
    % Return back to the original folder
    cd(masterfolder); 
    % Load the data from the next file
    loaddata(hObject, eventdata, handles);
else
    % If there aren't any more files in the directory, tell the user that there are no more files
    handles.nextfiledisplay.String = 'No more files to display';
    % Return back to the original folder
    cd(masterfolder); 
end


% --- Executes on button press in overlay_checkbox.
function overlay_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to overlay_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of overlay_checkbox
state = get(hObject,'Value');
handles.overlayon = state;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in forward_slow.
function forward_slow_Callback(hObject, eventdata, handles)
% hObject    handle to forward_slow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,5)


% --- Executes on button press in backward_slow.
function backward_slow_Callback(hObject, eventdata, handles)
% hObject    handle to backward_slow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,-5)


% --- Executes on button press in forward_fast.
function forward_fast_Callback(hObject, eventdata, handles)
% hObject    handle to forward_fast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,10)


% --- Executes on button press in backward_fast.
function backward_fast_Callback(hObject, eventdata, handles)
% hObject    handle to backward_fast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,-10)


% This function is called when the user selects the >, <, >>, or << buttons
function scrolldata(hObject,eventdata,handles,jumptime_minutes)
overwrite = 0;
jumptime = jumptime_minutes*60*1000; % convert minutes to milliseconds
handles.windowstarttime = handles.windowstarttime+jumptime;
if handles.dataindex<=length(handles.vname) % Vital Signs
    [~,handles.startindex] = min(abs(handles.vt-handles.windowstarttime));
else % Waveforms
    [~,handles.startindex] = min(abs(handles.wt-handles.windowstarttime));
end
plotdata(hObject, eventdata, handles, overwrite)


% --- Executes on button press in forward_hour.
function forward_hour_Callback(hObject, eventdata, handles)
% hObject    handle to forward_hour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,60)

% --- Executes on button press in back_hour.
function back_hour_Callback(hObject, eventdata, handles)
% hObject    handle to back_hour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,-60)
