function [pb_indx,pb_time,tag,tagname] = periodicbreathing(filename)
addpath('PB')

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
    pb_indx = [];
    pb_time = [];
    tag = [];
    tagname = [];
    return
else
    load(resultfilename,'result_name','result_data');
    if ~exist('result_name','var') % if it is an old version of the results file (I am not 100% sure if this bit of code works)
        pb_indx = [];
        pb_time = [];
        tag = [];
        tagname = [];
        return
    end
end

% Find the apnea probability data
if sum(contains(result_name,'/Results/Apnea-III'))
    dataindex = ismember(result_name,'/Results/Apnea-III');
elseif sum(contains(result_name,'/Results/Apnea-II'))
    dataindex = ismember(result_name,'/Results/Apnea-II');
elseif sum(contains(result_name,'/Results/Apnea-I'))
    dataindex = ismember(result_name,'/Results/Apnea-I');
else
    pb_indx = [];
    pb_time = [];
    tag = [];
    tagname = [];
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
[tag,tagname]=threshtags(pb_indx,pb_time,0.6,1,0,0); % This threshold was chosen from Mary Mohr's thesis