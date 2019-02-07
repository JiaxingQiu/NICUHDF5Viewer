function [results,vt,tag,tagname] = dataavailable(filename,vdata,vname,vt,pmin,tmin,signame,removeneg)
% This identifies periods where there are data present for each vital sign
% or waveform
%
% INPUT:
% filename:  char array path to hdf5 file
% vdata:     if it is empty, grabneededdata will extract the needed data
% vname:     if it is empty, grabneededdata will extract the needed data
% vt:        if it is empty, grabneededdata will extract the needed data
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap between crossings to join (default zero)
% signame can be any one of the following:
%    'Pulse'
%    'HR'
%    'SPO2_pct'
%    'Resp'
%    'ECGI'
%    'ECGII'
%    'ECGIII'
% removeneg: If 1, remove all values <1. If 0, remove all -32768 values

negthresh = 0; % we want to tag all points with values above a certain threshold
threshold = 0.5;

[outdata,vt,~,fs] = grabneededdata(filename,vdata,vname,vt,signame);

% If the necessary data isn't available, return empty matrices & exit
if isempty(vt)
    results = [];
    tag = [];
    tagname = [];
    return
end

if removeneg
    outdata(outdata<=1) = nan; % Remove negative values
else
    outdata(outdata==-32768) = nan; % Remove empty values
end
binarydata = ~isnan(outdata);
[tag,tagname]=threshtags(binarydata,vt,threshold,ceil(pmin*fs),tmin,negthresh);

% Store timepoints in a binary array
[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(outdata),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end