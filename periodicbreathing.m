function [pb_indx,pb_time,tag,tagname] = periodicbreathing(info,lead,result_tagtitle,result_data)
% periodicbreathing grabs the results from the apnea detection (first
% looking for apnea detection using ecg lead III, then II, then I, then no
% lead) and runs Mary Mohr's periodic breathing algorithm on it to
% calculate the probability of being in periodic breathing. Probabilities
% >0.6 (from Mohr's thesis) are tagged as periodic breathing events.
%
% INPUT:
% info:             from getfileinfo - if empty, it will go get it
% lead:             value from 0 to 3 indicating lead of interest. 0 = no lead
%                   default empty => all leads
% result_tagtitle   name of results
% result_data       results data

if ~exist('result_tagtitle','var'),result_tagtitle=[];end
if ~exist('result_data','var'),result_data=[];end
if ~exist('lead','var'),lead=[];end

% Add algorithm folders to path
if ~isdeployed
    addpath('.\PB')
end

% Initialize output variables in case the necessary data isn't available
pb_indx = [];
pb_time = [];
tag = [];
tagname = [];
    
% Add the wavelet pattern to Matlab
%load('Wavelets_Info.mat','Wavelets_Info')
load('wavelets.inf.mat','Wavelets_Info')
setappdata(0,'Wavelets_Info',Wavelets_Info);


%Default is all leads
apneaname='/Results/Apnea'; 
version=3;
% If a single lead is chosen:
if ~isempty(lead)
    filename={'/Results/Apnea-NoECG','/Results/Apnea-I','/Results/Apnea-II','/Results/Apnea-III'}';
    if lead>=0&&lead<=3
        apneaname=filename{lead+1};
        version=4;
    end
end

% Check if we have just run the apnea detector
unTomb=[];
Ttime=[];
if ~isempty(result_tagtitle)
    idx = findresultindex(apneaname,version,result_tagtitle);
    apneaindex=find(idx);
    if ~isempty(apneaindex)
        apneaindex=apneaindex(1);
        data = result_data(apneaindex);
        unTomb = data.data;
        Ttime = data.time; % Need to make sure this is okay for all types of data
    end
end
% If we haven't just run the apnea detector, load apnea data
if isempty(unTomb)
    [data,~,~] = formatdata(apneaname,info,3,1);
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
[tag,tagname]=threshtags2(pb_indx,pb_time,0.6,1,0,0,2); % This threshold was chosen from Mary Mohr's thesis
