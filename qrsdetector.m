function qrs = qrsdetector(filename,lead,wdata,wname,wt,version)
% qrsdetector runs qrs detection on the indicated lead
%
% INPUT:
% filename: char array path to hdf5 file
% lead:     value from 0 to 3 indicating lead of interest. 0 = no lead
% wdata:    if it is empty, grabneededdata will extract the needed data
% wname:    if it is empty, grabneededdata will extract the needed data
% wt:       if it is empty, grabneededdata will extract the needed data
%
% OUTPUT:
% qrs.qt:    times of detected heartbeats
% qrs.qb:    beat number of detected heartbeats
% qrs.qgood: flag for good heartbeats

% Add algorithm folders to path
if ~isdeployed
    addpath('X:\Amanda\NICUHDF5Viewer\Apnea')
    addpath('X:\Amanda\NICUHDF5Viewer\QRSDetection')
end

% Initialize output variables in case the necessary data isn't available
qrs = [];
    
% Make sure the filename field is in the right format
if iscell(filename)
    filename = char(filename);
    sprintf('Filename was a cell array. It has been converted to a char array.');
end

% Load in the EKG signal
if lead == 1
    [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGI');
elseif lead == 2
    [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGII');
elseif lead == 3
    [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGIII');
end
if isempty(ecgt) && lead>0
    return
end

if round(fs)~=fs
    fs = round(1/median(diff(ecgt)),1)*1000; % This is for Northwestern data which has a sampling frequency of 488.2813
end
% QRS Detection
gain = 1; % 400;
if lead~=0
    [qt,qb,qgood,~,~]=tombqrs(ecg,ecgt/1000,gain,fs);
end

qrs.lead = lead;
qrs.qt = qt;
qrs.qb = qb;
qrs.qgood = qgood;
qrs.version = version;