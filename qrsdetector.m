function qrs = qrsdetector(info,lead,version) 
% qrs = qrsdetector(filename,lead,wdata,wname,wt,version)
% qrsdetector runs qrs detection on the indicated lead
%
% INPUT:
% lead:         value from 1 to 3 indicating lead of interest
%               or name of ecg signal
% info:         from getfileinfo - if empty, it will go get it
% version:      version number for qrs detection algorithm
%
% OUTPUT:
% qrs.qt:       times of detected heartbeats (utc milliseconds)
% qrs.qb:       beat number of detected heartbeats
% qrs.qgood:    flag for good heartbeats
% qrs.name      name of ecg waveform
% qrs.ecgname   fixed name of ecg
% qrs.lead      lead number
% qrs.necg      number of ecg samples
% qrs.version   version number

if ~exist('version','var'),version=[];end

% Initialize output variables in case the necessary data isn't available
qrs = [];

% Load in the EKG signal
% if lead == 1
%     [data,~,fs] = formatdata1('ECGI',info,3,1);
% elseif lead == 2
%     [data,~,fs] = formatdata1('ECGII',info,3,1);
% elseif lead == 3
%     [data,~,fs] = formatdata1('ECGIII',info,3,1);
% end

% UTC milleseconds time format
tformat=3;
% structure data format
dformat=1;

%Find ecg name and lead number
ecgleads={'ECGI','ECGII','ECGIII'}';
%ecgname='ECGI';
ecgname='';
if ischar(lead)
    ecgname=lead;
    lead=strmatch(ecgname,ecgleads,'exact');
    if isempty(lead)       
        lead=length(ecgleads)+1;
    end
else
    try
        ecgname=ecgleads(lead);
    end
end

if isempty(ecgname),return,end

[data,~,fs] = formatdata(ecgname,info,3,1);

%if isempty(data) && lead>0
if isempty(data)
    return
end

% Add algorithm folders to path
% if ~isdeployed
%     addpath([fileparts(which('qrsdetector.m')) '\Apnea'])
%     addpath([fileparts(which('qrsdetector.m')) '\QRSDetection'])
% end

ecg = data.x;
ecgt = data.t; % date in UTC milliseconds format
name='';
ecgname='';
try
    name=data.name;
end
try
    ecgname=data.fixedname;
end

% QRS Detection
[qt,qecg,qs]=getqrs(ecg,ecgt,fs,info.tunit);

qrs.qt = qt; % times of detected beats (date in UTC milliseconds format?)
qrs.qecg = qecg; % ecg value at detected beat time
qrs.qs = qs; % segment of data used to run qrs detector
qrs.name = name;
qrs.ecgname = ecgname;
qrs.lead = lead;
qrs.necg = length(ecg);
qrs.version = version;