function [results,pt,tag,tagname,qrs] = apneadetector(filename,lead,wdata,wname,wt)
% apneadetector uses the resp waveform to calculate the probability of apnea.
% If an EKG sig is selected & available, it uses the signal to filter out
% heartbeats from the chest impedance waveform.
%
% INPUT:
% filename: char array path to hdf5 file
% lead:     value from 0 to 3 indicating lead of interest. 0 = no lead
% wdata:    if it is empty, grabneededdata will extract the needed data
% wname:    if it is empty, grabneededdata will extract the needed data
% wt:       if it is empty, grabneededdata will extract the needed data
%
% OUTPUT:
% results:  probability of apnea
% pt:       UTC time
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
    
% Make sure the filename field is in the right format
if iscell(filename)
    filename = char(filename);
    sprintf('Filename was a cell array. It has been converted to a char array.');
end

% Load in the respiratory signal
[resp,respt,~,CIfs] = grabneededdata(filename,wdata,wname,wt,'Resp');
if isempty(respt) % if there is no chest impedance signal, give up
    return
end

if round(CIfs,1)~=CIfs
    CIfs = 1/round(1/CIfs,3);
end

% Find the name of the result file
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
else
    resultfilename = strrep(filename,'.mat','_results.mat');
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
        [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGI');
    elseif lead == 2
        [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGII');
    elseif lead == 3
        [ecg,ecgt,~,fs] = grabneededdata(filename,wdata,wname,wt,'ECGIII');
    elseif lead == 0 
        ecg = [];
        ecgt = [];
        qt = [];
        qb = [];
        qgood =[];
    end
    if isempty(ecgt) && lead>0
        return
    end

    % QRS Detection
    gain = 1; % 400;
    if lead~=0
        ecgt = ecgt(~isnan(ecg));
        ecg = ecg(~isnan(ecg));
        [qt,qb,qgood,~,~]=tombqrs(ecg,ecgt/1000,gain,fs);
    end
    qrs.lead = lead;
    qrs.qt = qt;
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
