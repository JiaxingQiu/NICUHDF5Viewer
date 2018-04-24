function [signame, varname, handles] = loadhdf5data(hObject, eventdata, handles, s)
if contains(handles.value{1,s},'VitalSigns')
    signame = erase(handles.value{1,s},'/VitalSigns/');
    varname = handles.value{1,s};
else
    signame = erase(handles.value{1,s},'/Waveforms/');
    varname = handles.value{1,s};
end

readhdf5file(hObject,eventdata,handles)
handles = guidata(hObject);
timepath = [varname '/time'];

info = h5info(fullfile(handles.pathname, handles.filename));

% Find the Readings Per Time
readpertime = double(h5readatt(fullfile(handles.pathname, handles.filename),handles.value{1,s},'Readings Per Time'));

% Find Sampling Frequency for the Variable we care about
handles.fs = double(h5readatt(fullfile(handles.pathname, handles.filename),handles.value{1,s},'Sample Frequency (Hz)'));

% We want 20 minutes worth of sample data
if contains(varname,'Waveforms')
    handles.numsamps = round(60*20*handles.fs/readpertime);
else
    handles.numsamps = round(60*20*handles.fs); % 20 minutes 
end

% If one dataset in the file has a different number of samples than another
% dataset, if you try to show them sequentially, you could run into a
% problem. This checks for a change in the number of total samples and
% tells the script to update the sampend if the number of samples has
% changed. This should not trigger if switching from waveforms to vitals
% because both time stamp arrays *should* be sampled at the same rate

% BUT -  I NEED TO HANDLE THE CASE OF MULTIPLE PLOTS WITH SLIGHTLY
% DIFFERENT AMOUNTS OF DATA ALLOWED IN EACH PLOT BLARGHSHDSOAETA - maybe
% instead I should just ask for whatever data would be visible within the
% window frame - this would be hard though because there might be missing
% data so we'd have to read the individual time stamps or guess how many
% samples into the file we would be, which we are kindof already doing
% somewhere in this horrible file.
if isfield(handles,'totalsamples')
    oldtotal = handles.totalsamples;
    handles.totalsamples = length(h5read(fullfile(handles.pathname, handles.filename),timepath)); % Find the number of available samples in the file
    if handles.totalsamples~=oldtotal
        checksampend = 1;
    else
        checksampend = 0;
    end
else
    handles.totalsamples = length(h5read(fullfile(handles.pathname, handles.filename),timepath)); % Find the number of available samples in the file
    checksampend = 0;
end

% If this is the first time we are plotting something, select which sample number we start with and which we end with. Also, the window limits for the plot to 20 minutes
if ~isfield(handles,'sampstart')||checksampend
    handles.sampstart = 1;
    handles.sampend = handles.numsamps;
    handles.windowstarttime_utc = h5read(fullfile(handles.pathname,handles.filename),timepath,[1,1],[1,1]);
    [handles.windowstarttime,~,~] = utc2local(double(handles.windowstarttime_utc)/1000); % Find the time stamp of the first sample
    handles.windowendtime = addtodate(handles.windowstarttime,20,'minute');
end

% Don't ask for data that is outside the range of the dataset
if handles.totalsamples < handles.sampend
    if handles.totalsamples<handles.numsamps
        handles.sampstart = 1;
    else
        handles.sampstart = handles.totalsamples-handles.numsamps;
    end
    handles.sampend = handles.totalsamples;
end

guidata(hObject, handles);
time = h5read(fullfile(handles.pathname, handles.filename),timepath,[1,handles.sampstart],[1,handles.sampend-handles.sampstart+1]);
handles.dt = double(median(diff(time))); % Find the duration between samples (this is 2000 ms for GE Unity monitors)
tmax = 60*handles.dt; % This is our threshold for recognizing "breaks" in the file
if contains(varname,'Waveforms')
    sig = h5read(fullfile(handles.pathname, handles.filename),[handles.value{1,s} '/data'],[1,handles.sampstart],[1,(handles.sampend-handles.sampstart+1)*readpertime]);
    [time,~,~] = blocktime(sig,time,handles.dt,tmax); % The waveform time dataset is stored at the same frequency as the vital signs dataset, so we have to interpolate the in-between time stamps
else
    sig = h5read(fullfile(handles.pathname, handles.filename),[handles.value{1,s} '/data'],[1,handles.sampstart],[1,handles.sampend-handles.sampstart+1]);
end
handles.utctime = time;
% [time,~,~] = utc2local(double(time));
[time,~,~] = utc2local(double(time)/1000); % Convert to local time. The /1000 is needed because the utc2 local needs the time stamps in seconds, not ms.
handles.time = time;
handles.sig = sig;
guidata(hObject, handles);