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
    [data,~,fs] = formatdata('ECGI',info,3,1);
elseif lead == 2
    [data,~,fs] = formatdata('ECGII',info,3,1);
elseif lead == 3
    [data,~,fs] = formatdata('ECGIII',info,3,1);
end
if isempty(data) && lead>0
    return
end
ecg = data.x;
ecgt = data.t; % date in UTC milliseconds format

% QRS Detection
[qt,qecg,qs]=getqrs(ecg,ecgt,fs,info.tunit);

qrs.lead = lead;
qrs.qt = qt; % times of detected beats (date in UTC milliseconds format?)
qrs.qecg = qecg; % ecg value at detected beat time
qrs.qs = qs; % segment of data used to run qrs detector
qrs.version = version;