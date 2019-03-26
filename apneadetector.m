function [results,pt,tag,tagname,qrs] = apneadetector(info,lead,result_qrs)
% apneadetector uses the resp waveform to calculate the probability of apnea.
% If an EKG sig is selected & available, it uses the signal to filter out
% heartbeats from the chest impedance waveform.
%
% INPUT:
% info:     from getfileinfo - if empty, it will go get it
% lead:     value from 0 to 3 indicating lead of interest. 0 = no lead
% qrs:      result_qrs, if it exists, otherwise []
%
% OUTPUT:
% results:  probability of apnea
% pt:       UTC ms
% tag:      tags ready to be saved in the results file
% tagname:  tagnames ready to be saved in the results file
%

% Add algorithm folders to path
if ~isdeployed
    addpath('X:\Amanda\NICUHDF5Viewer\Apnea')
    addpath('X:\Amanda\NICUHDF5Viewer\QRSDetection')
end

% Initialize output variables in case the necessary data isn't available
results = [];
pt = [];
tag = [];
tagname = [];
qrs = [];

% Load in the respiratory signal
[data,~,info] = getfiledata(info,'Resp');
[data,~,~] = formatdata(data,info,3,1);
if isempty(data) % if there is no chest impedance signal, give up
    return
end
resp = data.x;
respt = data.t;
CIfs = data.fs;

if round(CIfs,1)~=CIfs
    CIfs = 1/round(1/CIfs,3);
end

% Find the name of the result file
if isfield(info,'resultfile')
    resultfilename = info.resultfile;
else
    resultfilename = [];
end

% Check to see if we input result_qrs into the function
if lead>0
    if ~isempty(result_qrs(lead))
        if ~isempty(result_qrs(lead).qrs)
            qt = result_qrs(lead).qrs.qt;
            qb = result_qrs(lead).qrs.qb;
            qgood = result_qrs(lead).qrs.qgood;
        end
    end
end
% Check to see if we already did QRS detection
if exist(resultfilename,'file') && lead>0
    varinfo = who('-file',resultfilename);
    if ismember('result_qrs',varinfo)
        load(resultfilename,'result_qrs')
        if size(result_qrs,2)>=lead
            if ~isempty(result_qrs(lead).qrs)
                qt = result_qrs(lead).qrs.qt;
                qb = result_qrs(lead).qrs.qb;
                qgood = result_qrs(lead).qrs.qgood;
            end
        end
    end
end

% If we haven't already done QRS detection, load the ECG signal and run QRS detection
if ~exist('qt')
    % Load in the EKG signal
    if lead == 1
        [data,~,info] = getfiledata(info,'ECGI');
    elseif lead == 2
        [data,~,info] = getfiledata(info,'ECGII');
    elseif lead == 3
        [data,~,info] = getfiledata(info,'ECGIII');
    elseif lead == 0 
        data = [];
        ecg = [];
        ecgt = [];
        qt = [];
        qb = [];
        qgood =[];
    end
    if lead > 0
        if isempty(data)
            return
        end
        [data,~,~] = formatdata(data,info,3,1);
        ecg = data.x;
        ecgt = data.t;
        fs = data.fs;
        if isempty(ecgt)
            return
        end
        % QRS Detection
        gain = 1; % 400;
        ecgt = ecgt(~isnan(ecg));
        ecg = ecg(~isnan(ecg));
        [qt,qb,qgood,~,~]=tombqrs(ecg,ecgt/1000,gain,fs);
    end
    qrs.lead = lead;
    qrs.qt = qt*1000;
    qrs.qb = qb;
    qrs.qgood = qgood;
end

% Eliminate nans from resp waveform
goodrespvals = ~isnan(resp);
resp = resp(goodrespvals);
respt = respt(goodrespvals);

% Calculate the apnea probability
[p,pt,pgood]=tombstone(resp,respt/1000,qt(qgood),qb(qgood),CIfs);

% Create apnea tags
if ~isempty(pgood)
    [tag,tagname,~]=wmtagevents(p,pgood,pt*1000);
else
    tag = [];
    tagname = [];
end

% Output the apnea probability
results = p;
pt = pt*1000;

end
