function qrs = qrsdetector(info,lead,version) 
% qrs = qrsdetector(filename,lead,wdata,wname,wt,version)
% qrsdetector runs qrs detection on the indicated lead
%
% INPUT:
% lead:     value from 0 to 3 indicating lead of interest. 0 = no lead
% info:     from getfileinfo - if empty, it will go get it
% version:  version number for qrs detection algorithm
%
% OUTPUT:
% qrs.qt:    times of detected heartbeats (utc milliseconds)
% qrs.qb:    beat number of detected heartbeats
% qrs.qgood: flag for good heartbeats

% Add algorithm folders to path
if ~isdeployed
    addpath('X:\Amanda\NICUHDF5Viewer\Apnea')
    addpath('X:\Amanda\NICUHDF5Viewer\QRSDetection')
end

% Initialize output variables in case the necessary data isn't available
qrs = [];

% Load in the EKG signal
if lead == 1
    [data,~,info] = getfiledata(info,'ECGI');
elseif lead == 2
    [data,~,info] = getfiledata(info,'ECGII');
elseif lead == 3
    [data,~,info] = getfiledata(info,'ECGIII');
end
[data,~,~] = formatdata(data,info,3,1);
if isempty(data) && lead>0
    return
end
ecg = data.x;
ecgt = data.t; % date in UTC milliseconds format
fs = data.fs;

% QRS Detection
gain = 1; % 400;
if lead~=0
    [qt,qb,qgood,~,~]=tombqrs(ecg,ecgt/1000,gain,fs); % tombqrs expects time in seconds
end

qrs.lead = lead;
qrs.qt = qt*1000; % date in UTC milliseconds format
qrs.qb = qb;
qrs.qgood = qgood;
qrs.version = version;