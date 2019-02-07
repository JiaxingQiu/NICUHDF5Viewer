function [results,vt,tag,tagname] = bradydetector(filename,vdata,vname,vt,threshold,pmin,tmin)
% This bradycardia detection algorithm tags bradycardia events based on the
% thresholds and joining rules in the input array

% INPUT:
% filename:  char array path to hdf5 file
% vdata:     if it is empty, grabneededdata will extract the needed data
% vname:     if it is empty, grabneededdata will extract the needed data
% vt:        if it is empty, grabneededdata will extract the needed data
% threshold: hr (<=) threshold for bradycardia event. If you want <80, set to 79.99 or the like
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap (ms) between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for bradycardia and 0 for no bradycardia
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%

% Load in the heart rate signal
[hrdata,vt,~,fs] = grabneededdata(filename,vdata,vname,vt,'HR');

% If the necessary data isn't available, return empty matrices & exit
if isempty(vt)
    results = [];
    tag = [];
    tagname = [];
    return
end

% Remove negative HR values
hrdata(hrdata<=1) = nan;
% period = median(diff(vt/1000));
% fs = 1/period;

isutc = strcmp(h5readatt(filename,'/','Timezone'),'UTC');
if ~isutc % The time is already in datenum format, so we need to convert the milliseconds to d
    tmin = datenum(duration(0,0,0,tmin));
end

% Tag bradycardia events
[tag,tagname]=threshtags(hrdata,vt,threshold,ceil(pmin*fs),tmin,1);

% Store bradycardia time points in a binary array
[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(hrdata),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end