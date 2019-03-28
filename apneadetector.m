function [results,pt,tag,tagname,qrs] = apneadetector(info,lead,result_qrs)
% apneadetector uses the resp waveform to calculate the probability of apnea.
% If an EKG sig is selected & available, it uses the signal to filter out
% heartbeats from the chest impedance waveform.
%
% INPUT:
% info:        from getfileinfo - if empty, it will go get it
% lead:        value from 0 to 3 indicating lead of interest. 0 = no lead
% result_qrs:  result_qrs, if it exists, otherwise []
%
% OUTPUT:
% results:     probability of apnea
% pt:          UTC ms
% tag:         tags ready to be saved in the results file
% tagname:     tagnames ready to be saved in the results file
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
try
    qt = result_qrs(lead).qrs.qt;
    qb = result_qrs(lead).qrs.qb;
    qgood = result_qrs(lead).qrs.qgood;
catch
    try
        load(resultfilename,'result_qrs')
        qt = result_qrs(lead).qrs.qt;
        qb = result_qrs(lead).qrs.qb;
        qgood = result_qrs(lead).qrs.qgood;
    catch
        % Load in the EKG signal
        if lead == 1
            [data,~,~] = formatdata('ECGI',info,3,1);
        elseif lead == 2
            [data,~,~] = formatdata('ECGII',info,3,1);
        elseif lead == 3
            [data,~,~] = formatdata('ECGIII',info,3,1);
        elseif lead == 0 
            data = [];
            qt = [];
            qb = [];
            qgood =[];
        end
        if lead > 0
            if isempty(data)
                return
            end
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
            [qt,qb,qgood,~,~]=tombqrs(ecg,ecgt/1000,gain,fs); % Needs seconds as an input and returns seconds as an output
        end
        qrs.lead = lead;
        qrs.qt = qt*1000; % convert seconds back to ms
        qrs.qb = qb;
        qrs.qgood = qgood;
    end
end


% Eliminate nans from resp waveform
goodrespvals = ~isnan(resp);
resp = resp(goodrespvals);
respt = respt(goodrespvals);

% Calculate the apnea probability
[p,pt,pgood]=tombstone(resp,respt/1000,qt(qgood)/1000,qb(qgood),CIfs); % Needs seconds as an input and returns seconds as an output 
pt = pt*1000; % convert seconds back to ms

% Create apnea tags
if ~isempty(pgood)
    [tag,tagname,~]=wmtagevents(p,pgood,pt);
else
    tag = [];
    tagname = [];
end

% Output the apnea probability
results = p;

end
