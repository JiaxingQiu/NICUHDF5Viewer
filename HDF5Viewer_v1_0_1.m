function varargout = HDF5Viewer_v1_0_1(varargin)
% HDF5VIEWER_V1_0_1 MATLAB code for HDF5Viewer_v1_0_1.fig
%
%      This viewer was developed by Amanda Edwards at the University of
%      Virginia with the help of code created by Doug Lake at the
%      University of Virginia. This graphical user interface allows users
%      to:
%
%      - View data from hdf5 files
%      - View multiple datasets at once on non-overlapping axes
%      - Interactively zoom using the mouse
%      - If desired, overlay multiple signals by checking the 'overlay box'
%      - Scroll forward and backward in the file
%      - Run QRS detection on waveform data
%      - Allow the user to choose to show only high-priority datasets or
%      all datasets contained in the file by checking a box
%      - This code is designed to work with HDF5 files produced using
%      UFC
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

% Last Modified by GUIDE v2.5 11-Mar-2019 14:08:06

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


%%%%%%%%%%%%%%%%%%%% BASIC GUI BACKGROUND CODE %%%%%%%%%%%%%%%%%%%%%


% --- Executes just before HDF5Viewer_v1_0_1 is made visible.
function HDF5Viewer_v1_0_1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HDF5Viewer_v1_0_1 (see VARARGIN)

% Choose default command line output for HDF5Viewer_v1_0_1
handles.output = hObject;
if ~isdeployed
    addpath('TabManager');
end
% Initialise tabs
handles.tabManager = TabManager( hObject );

% Set-up a selection changed function on the create tab groups
tabGroups = handles.tabManager.TabGroups;
for tgi=1:length(tabGroups)
    set(tabGroups(tgi),'SelectionChangedFcn',@tabChangedCB)
end

% Initialize Variables
handles.overlayon = 0; % Set the default to not overlay signals

% Update handles structure
guidata(hObject, handles);


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


%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in loadhdf5button: LOAD HDF5.
function loadhdf5button_Callback(hObject, eventdata, handles)
% hObject    handle to loadhdf5button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.filename, handles.pathname] = uigetfile({'*.hdf5';'*.mat'}, 'Select an hdf5 file');
if isequal(handles.filename,0)
	disp('User selected Cancel')
	set(handles.loadedfile,'string','No file selected');
else
    disp(['User selected ', fullfile(handles.pathname, handles.filename)])
	handles.nomorefiles = 0;
    loaddata(hObject, eventdata, handles);
end


% This is where the data is actually loaded in - the money code!!
function loaddata(hObject, eventdata, handles)
% Let the user know the GUI is currently working on loading the data
set(handles.loadedfile,'string','Loading...');
handles.tagalgstextbox.String = "";
waitfor(handles.loadedfile,'string','Loading...');
handles.nextfiledisplay.String = '';

% Remove startindex field from previous file
if isfield(handles,'startindex')
    handles = rmfield(handles,'startindex');
    handles = rmfield(handles,'windowstarttime');
end

% Remove plots from previous signal
if isfield(handles,'h')
    for i=1:length(handles.h)
        cla(handles.h(i))
        zoom out
        zoom reset
    end
end

% Check the file type
[~,~,ext]=fileparts(fullfile(handles.pathname, handles.filename));
handles.ishdf5=strcmp(ext,'.hdf5');

set(handles.loadedfile,'string','Loading File Info...');

% Get the info structure - this gets file attributes, loads result data and loads .dat file data
handles.info = getfileinfo(fullfile(handles.pathname, handles.filename));

handles.globalzeroms = handles.info.times(1); % ms to/from timezero/eventtime
handles.globalzerolocaldate = handles.globalzeroms/1000/86400 + handles.info.dayzero; % matlab date of the first time stamp
handles.globalzerodaystozero = handles.globalzeroms/1000/86400; % days between first data point and time zero/event time
corrupt = 0;

% Set the text below the Load HDF5 button to indicate that the results are loading
set(handles.loadedfile,'string','Loading Tags...');
waitfor(handles.loadedfile,'string','Loading Tags...');
[handles.rname,handles.rdata,handles.tagtitles,handles.tagcolumns,handles.tags,handles.rqrs] = getresultsfile3(handles.info.resultfile);

% Populate the Available Signals listbox with the signal names
handles.alldatasetnames = handles.info.name;
set(handles.listbox_avail_signals,'string',handles.alldatasetnames);

% Populate the Tag Category listbox with the tag categories, if they exist
if ~isempty(handles.tagtitles)
    set(handles.TagCategoryListbox,'string',handles.tagtitles(:,1));
else
    set(handles.TagCategoryListbox,'string','');
end
set(handles.TagCategoryListbox,'Value',1);

% Make sure the Tag Listbox is set to be empty (this clears old tags)
set(handles.TagListbox,'string','')

% Set the text below the Load HDF5 button to be the filename or a corrupt error
if corrupt == 1
    handles.loadedfile.String = [fullfile(handles.filename) " WARNING: File may be corrupt!!!"]; % Show the name of the loaded file
elseif corrupt == 2
    handles.loadedfile.String = 'URGENT: Delete old result file before continuing';
else
    handles.loadedfile.String = fullfile(handles.filename); % Show the name of the loaded file
end

% Clear highlighting to avoid errors
set(handles.listbox_avail_signals, 'Value', []); % This removes the selection highlighting from the listbox (this is important in case, for example, you have selected item 8 and then you load another file with only 5 items)
set(handles.overlay_checkbox,'value',0); % Uncheck the overlay checkbox
handles.overlayon = 0;

% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in listbox_avail_signals.
function listbox_avail_signals_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_avail_signals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_avail_signals contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_avail_signals
contents = cellstr(get(hObject,'String'));
handles.value = {contents{get(hObject,'Value')}};
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite);


function plotdata(hObject, eventdata, handles,overwrite)
% value = number(s) of the signal(s) chosen in Available Signals listbox
if ~isfield(handles,'value')
    set(handles.tagalgstextbox,'string','Please select a signal to plot in the Main tab')
    return
end
numsigs = length(handles.value);
set(handles.tagalgstextbox,'string','')

% Preallocate handles to the number of plot windows the user wants
if handles.overlayon
    handles.h = zeros(1,1);
else
    handles.h = zeros(numsigs,1);
end

% Loop through all of the selected items in Available Signals listbox
for s=1:numsigs
    % Load the data for the desired signal
    varname = handles.value{1,s}; % Find the name of the chosen signal
    handles.dataindex = find(ismember(handles.alldatasetnames,varname));
    [data,~,handles.info] = getfiledata(handles.info,varname);
    [handles.vdata,handles.t,handles.vname] = formatdata(data,handles.info,handles.tstampchoice,1);
    
    % Check to see if pre-defined limits/colors exist for the signal of interest
    [plotcolor,ylimmin,ylimmax] = customplotcolors(varname);
    
    % Set up the figure window(s) where the signal(s) will be plotted
    if handles.overlayon
        handles.h(s) = subplot(1,1,1,'Parent',handles.PlotPanel);
        y1 = ylim;
        hold on
        ylim auto;
        y2 = ylim;
        ylimmin = min([y1(1),ylimmin,y2(1)]);
        ylimmax = max([y1(2),ylimmax,y2(2)]);
        ylim([ylimmin ylimmax]);
    else
        handles.h(s) = subplot(numsigs,1,s,'Parent',handles.PlotPanel);
        if ~isnan(ylimmin)
            ylim([ylimmin ylimmax])
        else
            ylim auto;
        end
        hold on
        if overwrite % If we overwrite==1 and overlayon==0, clear the axes
            cla;
        end
    end
    
    % Set the Window Start and End Time AND Create the Day/Date Title Bar
    handles.windowsize = handles.windowsizeuserinput*60/86400; 
    if handles.tstampchoice==1
        if ~isfield(handles,'windowstarttime')
            handles.windowstarttime = handles.globalzerodaystozero;
        end
        if handles.windowstarttime<0
            daytodisp = -day(-handles.windowstarttime);
        else
            daytodisp = day(handles.windowstarttime);
        end
        daytodisp = ['Day: ' num2str(daytodisp)];
    elseif handles.tstampchoice==2
        if ~isfield(handles,'windowstarttime')
            handles.windowstarttime = handles.globalzerolocaldate;
        end
        daytodisp = datestr(handles.windowstarttime,'mm/dd/yy');
    end
    set(handles.DayTextBox,'string',daytodisp);
    handles.windowendtime = handles.windowstarttime+handles.windowsize;
    
    % Find start and end indices for signal
    [~,handles.startindex(s,1)] = min(abs(handles.vdata.t-handles.windowstarttime));
    [~,handles.endindex(s,1)] = min(abs(handles.vdata.t-handles.windowendtime));
    
    % Pull the data and timestamps for the window we want to plot
    handles.sig = handles.vdata.x(handles.startindex(s,1):handles.endindex(s,1));
    handles.tplot = handles.vdata.t(handles.startindex(s,1):handles.endindex(s,1));
    I = ~isnan(handles.sig); % Don't try to plot the NaN values
    
    % Actually plot the data
    if isempty(I) || sum(I)==0
        handles.plothandle(s) = plot(0,0);
        handles.plothandleI(s).I = I;
        ylabel({'No data for time period:'; strrep(varname,'_',' ')});
    else
        handles.plothandle(s) = plot(handles.tplot(I),handles.sig(I),plotcolor);
        handles.plothandleI(s).I = I;
        ylabel(strrep(varname,'_',' '));
    end
    
    % Handle the ability to zoom in and out while maintaining reasonable-looking timestamps
    if ~isdeployed
        addpath('zoomAdaptiveDateTicks');
    end
    zoomAdaptiveDateTicks('on')
    datetick('x',13) % Plots in HH:MM:SS
    
    % Set the x-axis limits
    xlim([handles.windowstarttime handles.windowendtime])
    zoom reset % This holds the zoom baseline to what has just been set. That way, if the user double clicks, it will bounce back to this state
    datetick('x',13,'keeplimits') % 'keeplimits' keeps the window limits at windowstarttime and windowendtime, otherwise,it would autoscale the axis
end
linkaxes(handles.h,'x') % This keeps the axes of all the subplots in line when zooming in and out
zoom on
% Update handles structure
guidata(hObject, handles);


function [plotcolor,ylimmin,ylimmax] = customplotcolors(varname)
plotcolor = 'k';
ylimmin = nan;
ylimmax = nan;

% Get the list of all possible variable strings that go with the desired signame
if ~isdeployed
    load('X:\Amanda\NICUHDF5Viewer\VariableNames','VariableNames')
else
    loadfilename = which(fullfile('VariableNames.mat'));
    load(loadfilename,'VariableNames')
end

% Find out if varname matches with any of the signal names in the varnamestruct
varnamestruct = getfield(VariableNames,'HR');
for i = 1:length(varnamestruct)
    if strcmp(varname,varnamestruct(i).Name)
        plotcolor = 'r';
        ylimmin = 0;
        ylimmax = 250;
    end
end

varnamestruct = getfield(VariableNames,'SPO2_pct');
for i = 1:length(varnamestruct)
    if strcmp(varname,varnamestruct(i).Name)
        plotcolor = 'b';
        ylimmin = 0;
        ylimmax = 100;
    end
end

varnamestruct = getfield(VariableNames,'Pulse');
for i = 1:length(varnamestruct)
    if strcmp(varname,varnamestruct(i).Name)
        plotcolor = 'm';
        ylimmin = 0;
        ylimmax = 250;
    end
end

varnamestruct = getfield(VariableNames,'Resp');
for i = 1:length(varnamestruct)
    if strcmp(varname,varnamestruct(i).Name)
        plotcolor = 'g';
    end
end

if contains(varname,'SIQ')
    plotcolor = 'k';
    ylimmin = 0;
    ylimmax = 3;
elseif contains(varname,'Waveforms/SPO2')
    plotcolor = 'b';
elseif contains(varname,'Results/CUartifact')
    plotcolor = 'r';
end

if contains(varname,'Results')
    ylimmin = 0;
    ylimmax = 1;
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
% Find all the files with the same extension in this directory
[~,~,ext]=fileparts(fullfile(handles.pathname, handles.filename));
ext = ['*' ext];
allfiles = dir(ext); 

filenames = strings(length(allfiles),1);
set(handles.TagCategoryListbox,'Value',1);
% Store the filenames as strings
for i=1:length(allfiles) 
    filenames(i) = string(allfiles(i).name);
end
filenames = filenames(~contains(filenames,'results'));
% Sort the filenames so we are always looking at them in the same order regardless of what order the computer grabs them
if length(allfiles)>1 
    filenames = sort(filenames);
end
% Find which file in the directory we are currently looking at
fileindex = find(filenames==handles.filename); 
if length(allfiles)>fileindex 
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


%%%%%%%%%%%%%%%%%%%%% CHANGING THE TIME AXIS %%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in TimestampMenu.
function TimestampMenu_Callback(hObject, eventdata, handles)
% hObject    handle to TimestampMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TimestampMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TimestampMenu

% Using the old tstampchoice, convert to time since event
if handles.tstampchoice == 1 % Time to Event
    neutralstartt = handles.windowstarttime;
    neutralendt = handles.windowendtime;
elseif handles.tstampchoice == 2 % Local Date
    neutralstartt = handles.windowstarttime-handles.info.dayzero;
    neutralendt = handles.windowendtime-handles.info.dayzero;
end

% Get the new value of tstampchoice in the dropdown menu
contents = cellstr(get(hObject,'String'));
tstampchoice = contents{get(hObject,'Value')};

% Update the window start and end times to match the new time format
if strcmp(tstampchoice,'Time to Event')
    handles.tstampchoice = 1;
    handles.windowstarttime = neutralstartt;
    handles.windowendtime = neutralendt;
elseif strcmp(tstampchoice,'Local Date')
    handles.tstampchoice = 2;
    handles.windowstarttime = neutralstartt+handles.info.dayzero;
    handles.windowendtime = neutralendt+handles.info.dayzero;
end
guidata(hObject, handles);
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite);


% --- Executes during object creation, after setting all properties.
function TimestampMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TimestampMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.tstampchoice = 1;
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%% SCROLLING %%%%%%%%%%%%%%%%%%%%%%%%%%%%


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


% --- Executes on button press in back_window.
function back_window_Callback(hObject, eventdata, handles)
% hObject    handle to back_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,-handles.windowsizeuserinput)


% --- Executes on button press in forward_window.
function forward_window_Callback(hObject, eventdata, handles)
% hObject    handle to forward_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scrolldata(hObject,eventdata,handles,handles.windowsizeuserinput)


% This function is called when the user selects the >, <, >>, or << buttons
function scrolldata(hObject,eventdata,handles,jumptime_minutes)
jumptime = datenum(seconds*jumptime_minutes*60); % convert minutes to seconds
handles.windowstarttime = handles.windowstarttime+jumptime;
handles.windowendtime = handles.windowstarttime + handles.windowsize;
% % Find start and end indices for signal
% for s=1:length(handles.value)
%     set(handles.h(s),'xlim',[handles.windowstarttime handles.windowendtime])
% end
guidata(hObject, handles);
overwrite = 1;
plotdata(hObject, eventdata, handles,overwrite);


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


%%%%%%%%%%%%%%%%%%%%%%%%%%%% TAGGING TAB %%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in TagCategoryListbox.
function TagCategoryListbox_Callback(hObject, eventdata, handles)
% hObject    handle to TagCategoryListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TagCategoryListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TagCategoryListbox
% contents = cellstr(get(hObject,'String'));
handles.tagtitlechosen = get(hObject,'Value');
UpdateTagListboxGivenCategoryChoice(hObject,eventdata,handles);


function UpdateTagListboxGivenCategoryChoice(hObject,eventdata,handles)
if ~isempty(handles.tags)
    tagsselected = handles.tags(handles.tagtitlechosen);
    if ~isfield(handles,'t')
        msgbox('Please select a signal to plot from the main tab');
        return
    end
    if size(tagsselected.tagtable,1)>0 %~isempty(tagsselected)
        starttimes = tagsselected.tagtable(:,strcmp(handles.tagcolumns(handles.tagtitlechosen).tagname,'Start')); % ms
        if handles.info.isutc % ms in utc time
            if handles.tstampchoice==1 % Days since time zero
                starttimes = starttimes-double(handles.info.utczero); % puts UTC date (ms) into ms since time zero
                handles.starttimesfigure = starttimes/86400/1000; % convert to days since time zero
                negstarts = handles.starttimesfigure<0;
                daytodisp = floor(abs(handles.starttimesfigure)); % convert ms to days
                daytodisp(negstarts) = -daytodisp(negstarts);
                daytodisp = [repmat('Day: ',length(daytodisp),1) char(pad(cellstr(num2str(daytodisp)),6,'left')) repmat('   ',length(daytodisp),1)];
            elseif handles.tstampchoice==2 % Date
                handles.starttimesfigure = utc2local(starttimes/1000); % convert UTC date (ms) to matlab date format
                daytodisp = datestr(handles.starttimesfigure,'mm/dd/yy HH:MM:SS');
            end
            duration = num2str(round(tagsselected.tagtable(:,strcmp(handles.tagcolumns(handles.tagtitlechosen).tagname,'Duration'))/1000)); % seconds
        else % ms since time zero
            if handles.tstampchoice==1 % Days since time zero
                handles.starttimesfigure = starttimes/86400/1000; % convert to days since time zero
                negstarts = handles.starttimesfigure<0; % tag starts before time zero
                daytodisp = floor(abs(handles.starttimesfigure)); % convert ms to days
                daytodisp(negstarts) = -daytodisp(negstarts);
                daytodisp = [repmat('Day: ',length(daytodisp),1) char(pad(cellstr(num2str(daytodisp)),6,'left')) repmat('   ',length(daytodisp),1)];
            elseif handles.tstampchoice==2 % Date
                handles.starttimesfigure = starttimes/86400/1000+handles.info.dayzero; % convert to days
                daytodisp = datestr(handles.starttimesfigure,'mm/dd/yy HH:MM:SS');
            end
            duration = num2str(round(tagsselected.tagtable(:,strcmp(handles.tagcolumns(handles.tagtitlechosen).tagname,'Duration'))/1000)); % seconds
        end
    else
        handles.starttimesfigure = [];
        daytodisp = [];
        duration = [];
    end

    try
        minimum = num2str(tagsselected.tagtable(:,strcmp(handles.tagcolumns(handles.tagtitlechosen).tagname,'Minimum')));
    catch
        minimum = zeros(length(duration),1);
    end
    spaces = repmat(' -- ',[size(duration,1),1]);
    set(handles.TagListbox,'string',[daytodisp spaces minimum spaces duration])
    set(handles.TagListbox,'Max',2);
    set(handles.TagListbox, 'Value', []); %%% FIX THIS!!!
end
% Update handles structure
guidata(hObject, handles);

% Update the plots
overwrite = 1;
plotdata(hObject, eventdata, handles, overwrite)


% --- Executes during object creation, after setting all properties.
function TagCategoryListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TagCategoryListbox (see GCBO)
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
% startcol = strcmp(handles.tagcolumns(handles.tagtitlechosen).tagname,'Start');
% starttimeofchosentag = handles.tags(handles.tagtitlechosen).tagtable(handles.tagchosen,startcol);
starttimeofchosentag = handles.starttimesfigure(handles.tagchosen);
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
drawnow
run_all_tagging_algs(fullfile(handles.pathname, handles.filename),handles.info,[])%%%%%%%%%%%%%%
% Get the info structure again now that the results file has been generated
handles.info = getfileinfo(fullfile(handles.pathname, handles.filename));
% Load the results data
[handles.rname,handles.rdata,handles.tagtitles,handles.tagcolumns,handles.tags,handles.rqrs] = getresultsfile3(handles.info.resultfile); % need to run this because handles.info doesn't have tagtitles in it
set(handles.tagalgstextbox,'string','');

handles.alldatasetnames = handles.info.name;
set(handles.listbox_avail_signals,'string',handles.alldatasetnames);

set(handles.TagCategoryListbox,'string',handles.tagtitles(:,1));
set(handles.TagCategoryListbox,'Value',1)
set(handles.TagListbox,'string','')
set(handles.TagListbox,'Value',1)
% Update handles structure
guidata(hObject, handles);


function jumpintodata(hObject,eventdata,handles,userselectedstart)
overwrite = 0;
handles.windowstarttime = userselectedstart;
[~,handles.startindex] = min(abs(handles.vdata.t-handles.windowstarttime));
plotdata(hObject, eventdata, handles, overwrite)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% CUSTOM TAGGING %%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in ButtonTagNewEvent.
function ButtonTagNewEvent_Callback(hObject, eventdata, handles)
% hObject    handle to ButtonTagNewEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zoom off
brush on
fighandle = gcf;
bO = brush(fighandle);


% --- Executes on button press in CustomTag.
function CustomTag_Callback(hObject, eventdata, handles)
% hObject    handle to CustomTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.brushhandle = brush(handles.figure1);
set(handles.brushhandle,'Color',[.6 .2 .1],'Enable','on');
% Update handles structure
guidata(hObject, handles);


function customtagtextentry_Callback(hObject, eventdata, handles)
% hObject    handle to customtagtextentry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of customtagtextentry as text
%        str2double(get(hObject,'String')) returns contents of customtagtextentry as a double


% --- Executes during object creation, after setting all properties.
function customtagtextentry_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customtagtextentry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AcceptTagButton.
function AcceptTagButton_Callback(hObject, eventdata, handles)
% hObject    handle to AcceptTagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Grab the custom tag name from the text box
customtaglabel = get(handles.customtagtextentry, 'string');
newtagname = ['/Results/CustomTag/' customtaglabel];

% Grab the brushed data from the window
notfoundyet = 1;
s = 1;
while notfoundyet && s<=length(handles.plothandle)
    brushedIdx = logical(handles.plothandle(s).BrushData)'; % This gives the indices of the highlighted data within the plotted window, but not within the whole dataset
    if sum(brushedIdx)>0
        windowtimestamps = handles.plothandle(s).XData;
        taggedtimestamps = windowtimestamps(brushedIdx);
        if handles.tstampchoice==1
            taggedtimestampsms = round(taggedtimestamps*86400*1000); % convert from days since time zero to ms since time zero
        elseif handles.tstampchoice==2
            taggedtimestampsms = round((taggedtimestamps-handles.info.dayzero)*86400*1000); % convert from matlab date to ms since time zero
        end
        [fulldataset,~] = ismember(handles.info.times,taggedtimestampsms); % Put the brushed data from the window into the context of the full dataset and retrieve the indices of the global timestamps which match
        % Fill in all the timepoints with ones between the first and last selected point
        firstindex = find(fulldataset==1,1);
        lastindex = find(fulldataset==1,1,'last');
        fulldataset(firstindex:lastindex)=1;
        handles.plothandle(s).BrushData = []; % Remove the brushing
        notfoundyet=0;
    end
    s=1+s;
end

% Turn this into tags
pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
[tag,tagcol]=threshtags(~fulldataset,handles.info.times+handles.info.utczero,0.5,pmin,tmin); % the +handles.info.utczero converts time stamps from (ms from time zero) to (utc ms)

% Load the results data in in the regular results file format
if ~isfield(handles,'rname')
    [handles.rname,handles.rdata,handles.tagtitles,handles.tagcolumns,handles.tags,handles.result_qrs] = getresultsfile3(resultsfilename);
end

% Add the custom tags to the results file data in the format expected by the results file
[handles.rname,handles.rdata,handles.tags,handles.tagcolumns,handles.tagtitles,~] = addtoresultsfile3(newtagname,fulldataset,handles.info.times+handles.info.utczero,tag,tagcol,[],handles.rname,handles.rdata,handles.tags,handles.tagcolumns,handles.tagtitles,handles.rqrs);

handles.alldatasetnames = [handles.info.name; newtagname]; % NOTE: You must save the tags before changing the tag name, otherwise the old tags will no longer be accessible...I think
set(handles.TagCategoryListbox,'string',handles.tagtitles(:,1));

% Update which tagged events are shown
categorychoice = get(handles.TagCategoryListbox, 'Value'); 
set(handles.TagCategoryListbox, 'Value', categorychoice);
if ~isfield(handles,'tagtitlechosen')
    handles.tagtitlechosen = categorychoice;
end
UpdateTagListboxGivenCategoryChoice(hObject,eventdata,handles);


% --- Executes on button press in SaveAllCustomTagsButton.
function SaveAllCustomTagsButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveAllCustomTagsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Find the Result Filename
if contains(fullfile(handles.pathname, handles.filename),'.hdf5')
    resultfilename = strrep(fullfile(handles.pathname, handles.filename),'.hdf5','_results.mat');
else
    resultfilename = strrep(fullfile(handles.pathname, handles.filename),'.mat','_results.mat');
end

% Name the data we are saving
result_data = handles.rdata;
result_name = handles.rname;
result_tags = handles.tags;
result_tagcolumns = handles.tagcolumns;
result_tagtitle = handles.tagtitles;

% Tell the user we are in the process of saving the results file
set(handles.tagalgstextbox,'string','Saving custom tags...');
drawnow
set(handles.SaveAllCustomTagsButton,'string','Saving...','enable','off');
drawnow

% Save the results file
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','-append');

% Tell the user we are done saving the results file
set(handles.tagalgstextbox,'string','Done Saving Custom Tags');
drawnow
set(handles.SaveAllCustomTagsButton,'string','Save All Custom Tags','enable','on');
drawnow


%%%%%%%%%%%%%%%%%%%%%%%%%%%% HELP MENU %%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --------------------------------------------------------------------
function help_menu_top_level_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_top_level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function help_menu_load_file_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_load_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Load a File:';
    'Load in an hdf5 file by clicking the "Load HDF5" button on the left side of the screen. Choose the hdf5 file of interest. A "Loading..." message will appear below the Load button. Once loading completes, the name of the file will appear where the "Loading..." message previously was.';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_display_data_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_display_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Display Data in the File:';
    'To display data from one of the variables, click the variable name in the white box. Twenty minutes of data will display on the screen.'; 
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_display_multiple_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_display_multiple (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Display Multiple Datasets at Once:';
    '- To display multiple variables at once, with each on its own plot, select multiple variables in the left menu by using the SHIFT or CTRL keys.';
    '- To overlay multiple variables on the same plot, click the "Overlay" checkbox at the bottom of the screen, then select (using the SHIFT or CTRL keys) the different variables you want to overlay.';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_browse_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Browse Through the Data:';
    'To browse through the data, click the buttons at the bottom of the screen to move through the file. To zoom in on the data, click and drag a box around the desired portion of the image you want to zoom in on, or use the mouse scroll wheel.';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_run_algs_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_run_algs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Run Algorithms';
    '- Select the Tagged Events Tab';
    '- Click the Run Tagging Algorithms Button';
    '- Wait until the white listboxes on that page populate';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_alg_results_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_alg_results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Look at Algorithm Results';
    '- Select the Tagged Events Tab';
    '- Select in the top box what category of events you want to look at';
    '- The tagged events should populate in the lower white box';
    '- You can click on one of these tagged events to show the event in the viewer';
    '- If you want to see details about the tag, go back to the Main tab. Then you should see the result names pop up in the bottom of the list. Some algorithms such as QRS detection and Data Available do not create plottable results, so you will not see an entry in the list for them. You can highlight the name of the tag to plot it along with the other signals you want to plot.';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_custom_tags_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_custom_tags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'To Custom Tag Events:';
    '- Go to the Tagged Events Tab';
    '- Enter a custom tag name in the small white box';
    '- Click the Start Tag Button';
    '- Click and drag in the figure window to highlight a portion of the data';
    '- Hit the Accept Tag button';
    '- The tag should show up in the large white boxes above';
    '- The tag should also show up in the Main Tab under the list of signals';
    '- You can tag multiple instances within the file with the same name and they will all be conglomerated under a single tag category with separate tags';
    '- When you are finished adding tags, hit the Save All Custom Tags Button';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_sparse_timestamps_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_sparse_timestamps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
    'If the timestamps become sparse on the x-axis:';
    '- If the x-axis timestamps become very sparse, hit the Update button to increase the number of points displayed.';
    '';
},'Help')

% --------------------------------------------------------------------
function help_menu_about_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({
'HDF5Viewer v2.7';
'This program allows you to browse the contents of HDF5 files and run algorithms on the data';
'';
},'Help')

