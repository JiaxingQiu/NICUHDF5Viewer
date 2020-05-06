function [results,vt,tag,tagname] = dataavailable(info,pmin,tmin,signame,removeneg)
% This identifies periods where there are data present for each vital sign
% or waveform
%
% INPUT:
% info:      from getfileinfo - if empty, it will go get it
% pmin:      minimum number of points below threshold (default one)
% tmin:      time gap between crossings to join (default zero)
% signame can be any one of the following (or a specific signal name):
%    'Pulse'
%    'HR'
%    'SPO2_pct'
%    'Resp'
%    'ECGI'
%    'ECGII'
%    'ECGIII'
% removeneg: If 1, remove all values <1. If 0, remove all -32768 values

% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];
    
negthresh = 0; % we want to tag all points with values above a certain threshold
threshold = 0.5;

[data,~,~] = getfiledata(info,signame);
[data,~,~] = formatdata(data,info,3,1);
if isempty(data) % If the necessary data isn't available, return empty matrices & exit
    return
end
outdata = data.x;
vt = data.t;
fs = data.fs;

% Remove duplicate timestamps. Only keep the x value relating to the last
% copy of a given timestamp;
[vt,ia] = unique(vt,'last');
outdata = outdata(ia);

vtdiff = diff(vt/1000)>(1/fs)*2;

if removeneg
    outdata(outdata<=1) = nan; % Remove negative values
else
    outdata(outdata==-32768) = nan; % Remove empty values
end

binarydata = ~isnan(outdata);
binarydata = double(binarydata);
binarydata2 = zeros(length(outdata),1);
binarydata2(logical([vtdiff; 0])) = 1;
[tag,tagname]=dataavailabletags(binarydata,vt,threshold,ceil(pmin*fs),tmin,negthresh,binarydata2);

results = [];
vt = [];