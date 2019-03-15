function [results,vt,tag,tagname] = bradydetector(info,threshold,pmin,tmin)
% This bradycardia detection algorithm tags bradycardia events based on the
% thresholds and joining rules in the input array

% INPUT:
% info:      from getfileinfo - if empty, it will go get it
% threshold: hr (<=) threshold for bradycardia event. If you want <80, set to 79.99 or the like
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap (ms) between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for bradycardia and 0 for no bradycardia
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%


% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];

% Load in the hr signal
[data,~,info] = getfiledata(info,'HR');
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data)
    return
end
hrdata = data.x;
vt = data.t;
fs = data.fs;

% Remove negative HR values
hrdata(hrdata<=1) = nan;

% Tag bradycardia events
[tag,tagname]=threshtags(hrdata,vt,threshold,ceil(pmin*fs),tmin,1);

% Store bradycardia time points in a binary array
[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(hrdata),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end