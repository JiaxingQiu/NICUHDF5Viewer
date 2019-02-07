function [results,vt,tag,tagname] = desatdetector(filename,vdata,vname,vt,threshold,pmin,tmin)
% This desaturation detection algorithm tags desat events based on the
% thresholds and joining rules in the input array

% INPUT:
% filename:  char array path to hdf5 file
% vdata:     if it is empty, grabneededdata will extract the needed data
% vname:     if it is empty, grabneededdata will extract the needed data
% vt:        if it is empty, grabneededdata will extract the needed data
% threshold: hr (<=) threshold for desat event. If you want <80, set to 79.99 or the like
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for desaturation and 0 for no desaturation
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%

% Load in the SPO2% signal
[spo2data,vt,~,fs] = grabneededdata(filename,vdata,vname,vt,'SPO2_pct');

% If the necessary data isn't available, return empty matrices & exit
if isempty(vt)
    results = [];
    tag = [];
    tagname = [];
    return
end

% Remove negative spo2 values
spo2data(spo2data<=1) = nan;
% period = median(diff(vt/1000));
% fs = 1/period;

isutc = strcmp(h5readatt(filename,'/','Timezone'),'UTC');
if ~isutc % The time is already in datenum format, so we need to convert the milliseconds to d
    tmin = datenum(duration(0,0,0,tmin));
end

% Tag desaturation events
[tag,tagname]=threshtags(spo2data,vt,threshold,ceil(pmin*fs),tmin,1);

% Store desaturation timepoints in a binary array
[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(spo2data),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end