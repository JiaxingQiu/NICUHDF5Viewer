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

% Last Modified by GUIDE v2.5 07-Jun-2018 16:37:08

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
if isfield(handles,'value')
    numsigs = length(handles.value);
    set(handles.tagalgstextbox,'string','')
else
    set(handles.tagalgstextbox,'string','Please select a signal to plot in the Main tab')
    return
end
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
    isSIQ = 0; % This is set to 1 if it is SIQ
    varname = handles.value{1,s};
    handles.dataindex = find(ismember(handles.alldatasetnames,varname));
    if handles.dataindex<=length(handles.vname)+length(handles.wname) % Determine if we are plotting a results file - here we are not plotting a results file
        if handles.ishdf5
            if strcmp(varname,'/VitalSigns/SIQ') % Because SIQ is not a root field, we need to get data from the corresponding signal
                varname = '/VitalSigns/SPO2-perc'; % Get the sample frequency from the corresponding signal
                isSIQ = 1;
            end
            try
                handles.fs = double(h5readatt(fullfile(handles.pathname, handles.filename),varname,'Sample Frequency (Hz)'));
            catch
                handles.fs = 1/(double(h5readatt(fullfile(handles.pathname, handles.filename),varname,'Sample Period (ms)'))/1000);
            end
            handles.unitofmeasure = cellstr(h5readatt(fullfile(handles.pathname, handles.filename),varname,'Unit of Measure'));
            handles.layoutversion = h5readatt(fullfile(handles.pathname, handles.filename),'/','Layout Version');
            handles.scale = double(h5readatt(fullfile(handles.pathname, handles.filename),[varname '/data'],'Scale'));
            % For layout version 3, scale is simply a multiplicative factor for the original value. To get the real value, you divide by scale. For layout version 4.0, a real value of 1.2 is stored as 12 with a scale of 1, where scale is stored as the power of 10, so to convert from 12 back to 1.2, you need to divide by 10^scale. Later in this code, when we are actually plotting the data, we divide by scale
            if str2double(handles.layoutversion{1}(1)) ~= 3 
                handles.scale = 10^handles.scale;
            end
            % For Philips IX monitors, the waveform sampling frequency is listed as either 4,8, or 16, but it should be 256.
            if handles.fs <=16
                if contains(varname,'Waveform')
                    handles.fs = 256;
                end
            end
        else
            handles.fs = 1; % For WUSTL at least, I am just hard-coding this
            handles.unitofmeasure = handles.vuom(s);
            handles.scale = 1;
        end
    else % We are plotting a results file
        handles.scale = 1;
    end
    if isSIQ
        varname = '/VitalSigns/SIQ';
    end
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
    if handles.ishdf5
        handles.windowsize = handles.windowsizeuserinput*60*1000; % 20 min in milliseconds is default
    else
        handles.windowsize = handles.windowsizeuserinput*60; 
    end
    if handles.dataindex<=length(handles.vname) % Vital Signs
        if ~isfield(handles,'startindex')
            handles.startindex = 1;
            handles.startindex = find(~isnan(handles.vdata(:,handles.dataindex)),1);
        end
        handles.windowstarttime = handles.vt(handles.startindex);
        handles.windowendtime = handles.windowstarttime+handles.windowsize; % default is 20 min from start time in utc in ms
        [~,handles.endindex] = min(abs(handles.vt-handles.windowendtime));
        handles.sig = handles.vdata(handles.startindex:handles.endindex,handles.dataindex);
        handles.utctime = handles.vt(handles.startindex:handles.endindex);
    elseif handles.dataindex<=length(handles.vname)+length(handles.wname) % Waveforms
        if ~isfield(handles,'startindexw')
            handles.startindexw = 1;
            handles.startindexw = find(~isnan(handles.wdata(:,handles.dataindex-length(handles.vname))),1);
        end
        handles.windowstarttime = handles.wt(handles.startindexw);
        [~,handles.startindexw] = min(abs(handles.wt-handles.windowstarttime));
        handles.windowstarttime = handles.wt(handles.startindexw);
        handles.windowendtime = handles.windowstarttime+handles.windowsize; % default is 20 min from start time in utc in ms
        [~,handles.endindexw] = min(abs(handles.wt-handles.windowendtime));
        handles.sig = handles.wdata(handles.startindexw:handles.endindexw,handles.dataindex-length(handles.vname));
        handles.utctime = handles.wt(handles.startindexw:handles.endindexw);
    else % Results 
        if ~isfield(handles,'startindexr')
            handles.startindexr = 1;
            handles.startindexr = find(~isnan(handles.rdata(:,handles.dataindex-length(handles.vname)-length(handles.wname))),1);
        end
        handles.windowstarttime = handles.rt(handles.startindexr);
        handles.windowendtime = handles.windowstarttime+handles.windowsize; % default is 20 min from start time in utc in ms
        [~,handles.endindexr] = min(abs(handles.rt-handles.windowendtime));
        handles.sig = handles.rdata(handles.startindexr:handles.endindexr,handles.dataindex-length(handles.vname)-length(handles.wname));
        handles.utctime = handles.rt(handles.startindexr:handles.endindexr);
    end
    if handles.ishdf5
        handles.localtime = utc2local(handles.utctime/1000);
    else
        handles.localtime = handles.utctime; % WUSTL data is in datenum format already
    end
    I = ~isnan(handles.sig); % Don't try to plot the NaN values
    if sum(I)==0
        handles.plothandle(s) = plot(0,0);
        ylabel({'No data for time period:'; varname});
    else
        handles.plothandle(s) = plot(handles.localtime(I),handles.sig(I)/handles.scale,plotcolor);
        ylabel(varname);
    end
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
elseif contains(varname,'SIQ')
    plotcolor = 'k';
    ylim([0 3])
elseif contains(varname,'SPO2-perc')
    plotcolor = 'b';
    ylim([0 100])
elseif contains(varname,'SPO2')
    plotcolor = 'b';
    ylim([0 100])
elseif contains(varname,'Waveforms/RR')
    plotcolor = 'g';
elseif contains(varname,'Waveforms/SPO2')
    plotcolor = 'b';
elseif contains(varname,'Results/CUartifact')
    plotcolor = 'r';
elseif contains(varname,'Results/WUSTLartifact')
    plotcolor = 'k';
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
[handles.filename, handles.pathname] = uigetfile({'*.hdf5';'*.mat'}, 'Select an hdf5 file');
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
handles.tagalgstextbox.String = "";
waitfor(handles.loadedfile,'string','Loading...');
handles.nextfiledisplay.String = '';
% try
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
    if contains(handles.filename,'.hdf5')
        handles.ishdf5 = 1;
        [handles.vdata,handles.vname,handles.vt,~]=gethdf5vital(fullfile(handles.pathname, handles.filename));
        [handles.wdata,handles.wname,handles.wt,~]=gethdf5wave(fullfile(handles.pathname, handles.filename));
    else % Load data from WashU
        handles.ishdf5 = 0;
        load(fullfile(handles.pathname, handles.filename),'values','vlabel','vt','vuom')
        handles.vuom = vuom;
        [handles.vdata,handles.vname,handles.vt,~]=getWUSTLvital(values,vt,vlabel);
        handles.wdata = [];
        handles.wname = [];
        handles.wt = [];
    end

    [handles.rdata,handles.rname,handles.rt,handles.tagtitles,handles.tagcolumns,handles.tags]=getresultsfile(fullfile(handles.pathname, handles.filename));
    handles.alldatasetnames = vertcat(handles.vname,handles.wname,handles.rname);
    % Show only the most useful signals as a default
    usefulfields = ["HR","SPO2-%","SPO2","SPO2-perc","SPO2-R","Waveforms/I","Waveforms/II","Waveforms/III","Waveforms/RR","Waveforms/SPO2"];
    usefulfieldindices = contains(string(handles.alldatasetnames),usefulfields);
    handles.usefuldatasetnames = handles.alldatasetnames(usefulfieldindices);
    set(handles.listbox_avail_signals,'string',handles.usefuldatasetnames);
    set(handles.TaggedEventsListbox,'string',handles.tagtitles);
    set(handles.TagListbox,'string','')
    handles.loadedfile.String = fullfile(handles.filename); % Show the name of the loaded file
% catch e
%     handles.loadedfile.String = e.message;
% end
set(handles.listbox_avail_signals, 'Value', []); % This removes the selection highlighting from the listbox (this is important in case, for example, you have selected item 8 and then you load another file with only 5 items)
set(handles.overlay_checkbox,'value',0); % Uncheck the overlay checkbox
set(handles.show_all_avail_fields_checkbox,'value',0);
handles.overlayon = 0;
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
handles.algchoice = contents{get(hObject,'Value')}; % returns selected item from popupmenu1
% Update handles structure
guidata(hObject, handles);


function callqrsdetection(hObject,eventdata,handles)
% run QRS detection on the selected signal with the designated lead, clear
% all current plots, and plot the results of the QRS detection in
% comparison to the heart rate plot
[hrt,hr,rrt,rr,ecgt,ecg,qrs] = runQRSDetection2(hObject,eventdata,handles);
handles.h(1) = subplot(2,1,1,'Parent',handles.PlotPanel);
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
xlim([utc2local(min(ecgt)/1000) utc2local(max(ecgt)/1000)])

handles.h(2) = subplot(2,1,2,'Parent',handles.PlotPanel);
[ecgt_local,~,~] = utc2local(ecgt/1000);
plot(ecgt_local,ecg,'k');
hold on
ylim auto
zoomAdaptiveDateTicks('on')
datetick('x',13)
plot(ecgt_local(qrs),ecg(qrs),'*')
xlim([utc2local(min(ecgt)/1000) utc2local(max(ecgt)/1000)])
linkaxes(handles.h,'x')
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
menuoptions = {'';'QRS Detection';'Placeholder for Algorithm';'Placeholder for Another'};
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
set(handles.listbox_avail_signals, 'Value', []); % This removes the selection highlighting from the listbox (this is important in case, for example, you have selected item 8 and then you load another file with only 5 items)
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
overwrite = 1;
plotdata(hObject, eventdata, handles,overwrite);


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
if handles.ishdf5
    jumptime = jumptime_minutes*60*1000; % convert minutes to milliseconds
else % for WUSTL data
    jumptime = jumptime_minutes*60; % convert minutes to seconds
end
handles.windowstarttime = handles.windowstarttime+jumptime;
if isfield(handles,'startindexw')
    [~,handles.startindexw] = min(abs(handles.wt-handles.windowstarttime));
end
if isfield(handles,'startindex')
    [~,handles.startindex] = min(abs(handles.vt-handles.windowstarttime));
end
if isfield(handles,'startindexr')
    [~,handles.startindexr] = min(abs(handles.rt-handles.windowstarttime));
end
% if handles.dataindex<=length(handles.vname) % Vital Signs
%     [~,handles.startindex] = min(abs(handles.vt-handles.windowstarttime));
% elseif handles.dataindex<=length(handles.vname)+length(handles.wname) % Waveforms
%     [~,handles.startindexw] = min(abs(handles.wt-handles.windowstarttime));
% else % Results
%     [~,handles.startindex] = min(abs(handles.rt-handles.windowstarttime));
% end
plotdata(hObject, eventdata, handles, overwrite)

function jumpintodata(hObject,eventdata,handles,userselectedstart)
overwrite = 0;
handles.windowstarttime = userselectedstart;
% if handles.dataindex<=length(handles.vname) % Vital Signs
%     [~,handles.startindex] = min(abs(handles.vt-handles.windowstarttime));
% elseif handles.dataindex<=length(handles.vname)+length(handles.wname) % Waveforms
%     [~,handles.startindex] = min(abs(handles.wt-handles.windowstarttime));
% else % Results
%     [~,handles.startindex] = min(abs(handles.rt-handles.windowstarttime));
% end
if isfield(handles,'startindexw')
    [~,handles.startindexw] = min(abs(handles.wt-handles.windowstarttime));
end
if isfield(handles,'startindex')
    [~,handles.startindex] = min(abs(handles.vt-handles.windowstarttime));
end
if isfield(handles,'startindexr')
    [~,handles.startindexr] = min(abs(handles.rt-handles.windowstarttime));
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


% --- Executes on button press in RunAlgorithmButton.
function RunAlgorithmButton_Callback(hObject, eventdata, handles)
% hObject    handle to RunAlgorithmButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.algchoice,'QRS Detection')
    addpath('QRSDetection');
    callqrsdetection(hObject,eventdata,handles);
end


% --------------------------------------------------------------------
function Help_menu_Callback(hObject, eventdata, handles)
% hObject    handle to Help_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Menu_help_instructions_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_help_instructions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({'HDF5Viewer 1.1';
'This program allows you to browse the contents of HDF5 files and run algorithms on the data';
'';
'To Load a File:';
'Load in an hdf5 file by clicking the "Load HDF5" button on the left side of the screen. A "Loading..." message will appear below the Load button. Once loading completes, the name of the file will appear where the "Loading..." message previously was. A small list of the most important variable names should populate in the white box.';
'';
'To Display All of the Data in the File:';
'To see all of the variables in the file click the "Show All Available Fields" checkbox at the bottom of the screen. To display data from one of the variables, click the variable name in the white box. Twenty minutes of data will display on the screen.'; 
''
'To Display Multiple Datasets at Once:';
'- To display multiple variables at once, with each on its own plot, select multiple variables in the left menu by using the SHIFT or CTRL keys.';
'- To overlay multiple variables on the same plot, click the "Overlay" checkbox at the bottom of the screen, then select (using the SHIFT or CTRL keys) the different variables you want to overlay.';
'';
'To Browse Through the Data:';
'To browse through the data, click the buttons at the bottom of the screen to move through the file. To zoom in on the data, click and drag a box around the desired portion of the image you want to zoom in on, or use the mouse scroll wheel.';
'';
'Using QRS Detection to Compute Heart Rate:';
'- First select a good EKG signal lead to display. Make sure the signal displayed in the window does not start with an empty signal. If it does, scroll (using the buttons at the bottom of the screen) to a part of the signal which does not begin with missing data.';
'- Go to the "Run Algorithms" tab.'; 
'- In the Dropdown menu, select the QRS Detection Algorithm.';
'- Hit Run.' 
'- A pink and a blue scatter plot should appear. The blue scatter plot shows the signal taken from the signal labeled "HR." The magenta scatter plot shows the heart rate calculated from the QRS detection algorithm.'; 
'- If you want to see the QRS detection for other parts of the data, you can scroll through the data by using the buttons at the bottom of the screen. When you see data where you want to run the QRS detection, simply click the "Run" button again.';
'';
'To Tag Bradycardias and Desaturation Events';
'- Select the Tagged Events Tab';
'- Click the Run Tagging Algorithms Button';
'- Wait until the white listboxes on that page populate';
'- Select in the top box what category of events you want to look at';
'- The tagged events should populate in the lower white box';
'- You can click on one of these tagged events to show the event in the viewer';
'- The first timestamp of that tagged event will be shown on the leftmost edge of the viewer window';
'';
'To Custom Tag Events: [IN PROGRESS - THIS HAS NOT BEEN FULLY TESTED]';
'- Go to the Tagged Events Tab';
'- Click the Start Tag Button';
'- Click and drag in the figure window to highlight a portion of the data';
'- Enter a custom tag name in the small white box';
'- Hit the Save Tag button';
'- The tag should show up in the large white boxes above';
'';
},'Help')



function WindowSize_Callback(hObject, eventdata, handles)
% hObject    handle to WindowSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WindowSize as text
%        str2double(get(hObject,'String')) returns contents of WindowSize as a double
handles.windowsizeuserinput = str2double(get(hObject,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function WindowSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WindowSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.windowsizeuserinput = str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in UpdateWindowSize.
function UpdateWindowSize_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateWindowSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite);


% --- Executes on selection change in TaggedEventsListbox.
function TaggedEventsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to TaggedEventsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TaggedEventsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TaggedEventsListbox
% contents = cellstr(get(hObject,'String'));
handles.tagtitlechosen = get(hObject,'Value');
tagsselected = handles.tags(handles.tagtitlechosen);
starttimes = datestr(utc2local(tagsselected.tagtable(:,strcmp(handles.tagcolumns,'Start'))/1000));
duration = num2str(round(tagsselected.tagtable(:,strcmp(handles.tagcolumns,'Duration'))/1000)); % seconds
minimum = num2str(tagsselected.tagtable(:,strcmp(handles.tagcolumns,'Minimum')));
spaces = repmat(' -- ',[size(duration,1),1]);
set(handles.TagListbox,'string',[starttimes spaces minimum spaces duration])
set(handles.TagListbox, 'Value', 1); %%% FIX THIS!!!
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function TaggedEventsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TaggedEventsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in TagListbox.
function TagListbox_Callback(hObject, eventdata, handles)
% hObject    handle to TagListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TagListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TagListbox
handles.tagchosen = get(hObject,'Value');
startcol = strcmp(handles.tagcolumns,'Start');
starttimeofchosentag = handles.tags(handles.tagtitlechosen).tagtable(handles.tagchosen,startcol);
jumpintodata(hObject,eventdata,handles,starttimeofchosentag);


% --- Executes during object creation, after setting all properties.
function TagListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TagListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in run_tagging_algorithms.
function run_tagging_algorithms_Callback(hObject, eventdata, handles)
% hObject    handle to run_tagging_algorithms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.tagalgstextbox,'string','Running...');
run_all_tagging_algs(fullfile(handles.pathname, handles.filename))
[handles.rdata,handles.rname,handles.rt,handles.tagtitles,handles.tagcolumns,handles.tags]=getresultsfile(fullfile(handles.pathname, handles.filename));
if isempty(handles.rdata)
    set(handles.tagalgstextbox,'string','File lacks variables needed to generate results file');
else
    set(handles.tagalgstextbox,'string','');
end
handles.alldatasetnames = vertcat(handles.vname,handles.wname,handles.rname);
set(handles.TaggedEventsListbox,'string',handles.tagtitles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in CustomTag.
function CustomTag_Callback(hObject, eventdata, handles)
% hObject    handle to CustomTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.brushhandle = brush(handles.figure1);
set(handles.brushhandle,'Color',[.6 .2 .1],'Enable','on');
% Update handles structure
guidata(hObject, handles);


function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveTag.
function SaveTag_Callback(hObject, eventdata, handles)
% hObject    handle to SaveTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Grab the custom tag name from the text box
customtaglabel = get(handles.edit3, 'string');

% Grab the brushed data from the window
notfoundyet = 1;
s = 1;
while notfoundyet && s<=length(handles.plothandle)
    brushedIdx = logical(handles.plothandle(s).BrushData)'; % This gives the indices of the highlighted data within the plotted window, but not within the whole dataset
    if sum(brushedIdx)>0
        handles.plothandle(s).BrushData = zeros(size(handles.plothandle(s).BrushData)); % Remove the brushing
        notfoundyet=0;
    end
    s=1+s;
end
fulldataset = zeros(length(handles.vt),1);
fulldataset(handles.startindex:handles.endindex,1) = brushedIdx; % This puts the brushed data in the context of the full dataset

% Turn this into tags
pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
[tag,tagname]=threshtags(~fulldataset,handles.vt,0.5,pmin,tmin);

% Add tags to results file
addtoresultsfile(fullfile(handles.pathname, handles.filename),['/Results/CustomTag/' customtaglabel],fulldataset,handles.vt,tag,tagname);

% Show the custom tag in the listbox
[handles.rdata,handles.rname,handles.rt,handles.tagtitles,handles.tagcolumns,handles.tags]=getresultsfile(fullfile(handles.pathname, handles.filename));
handles.alldatasetnames = vertcat(handles.vname,handles.wname,handles.rname);
set(handles.TaggedEventsListbox,'string',handles.tagtitles);

% Update which tagged events are shown
categorychoice = get(handles.TaggedEventsListbox, 'Value'); 
TagListbox_Callback(hObject, eventdata, handles)
TaggedEventsListbox_Callback(hObject, eventdata, handles)
set(handles.TaggedEventsListbox.hObject, 'Value', categorychoice);

% Update the plots
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite)

% Update handles structure
guidata(hObject, handles);
