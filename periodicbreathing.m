function [pb_indx,pb_time,tag,tagname] = periodicbreathing(filename)
% periodicbreathing grabs the results from the apnea detection (first
% looking for apnea detection using ecg lead III, then II, then I, then no
% lead) and runs Mary Mohr's periodic breathing algorithm on it to
% calculate the probability of being in periodic breathing. Probabilities
% >0.6 (from Mohr's thesis) are tagged as periodic breathing events.
%
% INPUT:
% filename: char array path to hdf5 file

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
% add_new_wavelets;
load('Wavelets_Info.mat','Wavelets_Info')
setappdata(0,'Wavelets_Info',Wavelets_Info);

% Find the name of the result file
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
else
    resultfilename = strrep(filename,'.mat','_results.mat');
end

% Load the result file
if ~exist(resultfilename,'file') %If there is no result file, stop.
    return
else
    load(resultfilename,'result_name','result_data');
    if ~exist('result_name','var') % if it is an old version of the results file (I am not 100% sure if this bit of code works)
        return
    end
end

% Find the apnea probability data
if sum(contains(result_name(:,1),'/Results/Apnea-III'))
    dataindex = ismember(result_name(:,1),'/Results/Apnea-III');
elseif sum(contains(result_name(:,1),'/Results/Apnea-II'))
    dataindex = ismember(result_name(:,1),'/Results/Apnea-II');
elseif sum(contains(result_name(:,1),'/Results/Apnea-I'))
    dataindex = ismember(result_name(:,1),'/Results/Apnea-I');
elseif sum(contains(result_name(:,1),'/Results/Apnea-NoECG'))
    dataindex = ismember(result_name(:,1),'/Results/Apnea-NoECG');
else
    return
end

% Load the apnea probability data
unTomb = result_data(dataindex).data;
Ttime = result_data(dataindex).time;

% Run the periodic breathing algorithm
[pb_indx,pb_time,~,~,~] = Calc_pb_wavelet(unTomb,Ttime);
if isrow(pb_indx)
    pb_indx = pb_indx';
    pb_time = pb_time';
end

% Create periodic breathing tags
[tag,tagname]=threshtags(pb_indx,pb_time,0.6,1,0,0); % This threshold was chosen from Mary Mohr's thesis
