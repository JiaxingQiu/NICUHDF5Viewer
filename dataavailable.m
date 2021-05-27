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
threshold = 0;

[data,~,~] = getfiledata(info,signame);
[data,~,~] = formatdata(data,info,3,1);
if isempty(data) % If the necessary data isn't available, return empty matrices & exit
    return
end
outdata = data.x;
vt = data.t;
fs = data.fs;

vtdiff = diff(vt)>(1/fs);

switch signame
    case 'Pulse'
        flat = isflat(outdata,fs,60);
    case 'HR'
        flat = isflat(outdata,fs,60);
    case 'SPO2_pct'
        flat = isflat(outdata,fs,600);
    case 'Resp'
        flat = isflat(outdata,fs,10);
    case 'ECGI'
        flat = isflat(outdata,fs,10);
    case 'ECGII'
        flat = isflat(outdata,fs,10);
    case 'ECGIII'
        flat = isflat(outdata,fs,10);
end
outdata(logical(flat)) = nan;

if removeneg
    outdata(outdata<=1) = nan; % Remove negative values
else
    outdata(outdata==-32768) = nan; % Remove empty values
end
binarydata = ~isnan(outdata);
[tag,tagname]=threshtags2(binarydata,vt,threshold,ceil(pmin*fs),tmin,negthresh,1);

results = [];
vt = [];