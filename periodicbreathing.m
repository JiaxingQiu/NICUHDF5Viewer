function [pb_indx,pb_time,tag,tagname] = periodicbreathing(info,lead,result_name,result_data)
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

% Check if we have just run the apnea detector
apneaindex = [];
if lead == 0
    filename = '/Results/Apnea-NoECG';
elseif lead == 1
    filename = '/Results/Apnea-I';
elseif lead == 2
    filename = '/Results/Apnea-II';
elseif lead == 3
    filename = '/Results/Apnea-III';
end
if sum(strcmp(result_name(:,1),filename))
    apneaindex = strcmp(result_name(:,1),filename);
end
if ~isempty(apneaindex)
    data = result_data(apneaindex);
    unTomb = data.data;
    Ttime = data.time; % Need to make sure this is okay for all types of data
end

% If we haven't just run the apnea detector, load apnea data
if isempty(apneaindex)
    [data,~,~] = formatdata(filename,info,3,1);
    if isempty(data)
        return
    end
    unTomb = data.x;
    Ttime = data.t;
end

% Run the periodic breathing algorithm
[pb_indx,pb_time,~,~,~] = Calc_pb_wavelet(unTomb,Ttime);
if isrow(pb_indx)
    pb_indx = pb_indx';
    pb_time = pb_time';
end

% Create periodic breathing tags
[tag,tagname]=threshtags(pb_indx,pb_time,0.6,1,0,0); % This threshold was chosen from Mary Mohr's thesis
