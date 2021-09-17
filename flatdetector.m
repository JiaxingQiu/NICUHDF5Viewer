function [results,vt,tag,tagname] = flatdetector(info,signame,duration)
% This algorithm tags events where signals is flat for prolonge periods
%
% INPUT:
% info:      from getfileinfo - if empty, it will go get it
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

%Default durations

if ~exist('duration','var')
    
switch signame
    case 'Pulse'
        duration=60;
    case 'HR'
        duration=60;        
    case 'SPO2_pct'
        duration=600;                
    case 'Resp'
        duration=60;
    otherwise
        duration=NaN;
end

end

if isnan(duration),return,end

[data,~,~] = getfiledata(info,signame);
[data,~,~] = formatdata(data,info,3,1);

if isempty(data) % If the necessary data isn't available, return empty matrices & exit
    return
end
x = data.x;
vt = data.t;
fs = data.fs;

tmin=0;
pmin=round(fs*duration)-1;

%Find when data is same as previous point
dx=[1;diff(x)];
same=dx==0;

[tag,tagname]=threshtags2(same,vt,0,pmin,tmin,0,1);

results = [];
vt =[];