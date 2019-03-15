function [results,vt,tag,tagname] = desatdetector(info,threshold,pmin,tmin)
% This desaturation detection algorithm tags desat events based on the
% thresholds and joining rules in the input array

% INPUT:
% info:      from getfileinfo - if empty, it will go get it
% threshold: hr (<=) threshold for desat event. If you want <80, set to 79.99 or the like
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for desaturation and 0 for no desaturation
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%

% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];

% Load in the spo2% signal
[data,~,info] = getfiledata(info,'SPO2_pct');
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data)
    return
end
spo2data = data.x;
vt = data.t;
fs = data.fs;

% Remove negative spo2 values
spo2data(spo2data<=1) = nan;

% Tag desaturation events
[tag,tagname]=threshtags(spo2data,vt,threshold,ceil(pmin*fs),tmin,1);

% Store desaturation timepoints in a binary array
[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(spo2data),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end