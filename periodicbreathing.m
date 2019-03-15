function [pb_indx,pb_time,tag,tagname] = periodicbreathing(info)
% periodicbreathing grabs the results from the apnea detection (first
% looking for apnea detection using ecg lead III, then II, then I, then no
% lead) and runs Mary Mohr's periodic breathing algorithm on it to
% calculate the probability of being in periodic breathing. Probabilities
% >0.6 (from Mohr's thesis) are tagged as periodic breathing events.
%
% INPUT:
% info:     from getfileinfo - if empty, it will go get it

% Add algorithm folders to path
if ~isdeployed
    addpath('X:\Amanda\NICUHDF5Viewer\PB')
end

% Initialize output variables in case the necessary data isn't available
pb_indx = [];
pb_time = [];
tag = [];
tagname = [];
    
% Add the wavelet pattern to Matlab
load('Wavelets_Info.mat','Wavelets_Info')
setappdata(0,'Wavelets_Info',Wavelets_Info);

% Load Apnea Data
[data,~,~] = getfiledata(info,'/Results/Apnea-I');
if isempty(data)
    [data,~,~] = getfiledata(info,'/Results/Apnea-II');
    if isempty(data)
        [data,~,~] = getfiledata(info,'/Results/Apnea-III');
        if isempty(data)
            [data,~,~] = getfiledata(info,'/Results/Apnea-NoECG');
            if isempty(data)
                return
            end
        end
    end
end
[data,~,~] = formatdata(data,info,3,1);
unTomb = data.x;
Ttime = data.t;

% Run the periodic breathing algorithm
[pb_indx,pb_time,~,~,~] = Calc_pb_wavelet(unTomb,Ttime);
if isrow(pb_indx)
    pb_indx = pb_indx';
    pb_time = pb_time';
end

% Create periodic breathing tags
[tag,tagname]=threshtags(pb_indx,pb_time,0.6,1,0,0); % This threshold was chosen from Mary Mohr's thesis
