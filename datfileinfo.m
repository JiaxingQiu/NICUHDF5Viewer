function info=datfileinfo(file)
%function info=datfileinfo(file)
%
%file       .dat file
%name       name of datasets to retrieve (empty=default => all) 
%
%data       structure with data and time stamps
%name       name of datasets
%info       structure with dataset attributes/names

if ~exist('name','var'),name=cell(0,1);end
if ischar(name),name={name};end

%Find scaling factors
[pathstr,~]=fileparts(file);
facfile=fullfile(pathstr,'ScalingFactors.txt');
if ~isempty(dir(facfile))
    fac=load(facfile);
else
    fac=[];
end

%Timestamps in UTC and ms
timeunit='ms';
tunit=1000;
timezone='UTC';
isutc=true;

info.file=file;

%Hard code dat file names
info.name={'/Waveforms/ECG','/Waveforms/RESP','/Waveforms/SPO2','/Waveforms/HR','/VitalSigns/SPO2','/VitalSigns/HR'}';
info.fixedname=fixedname(info.name);

info.facfile=facfile;
info.fac=fac;

nv=length(info.name);

%Hard code frequency and vital sign frequency
fs=200;
vfs=1;
T=1000;

%Get raw data and start date from file
[rawdata,start]=getrawdatdata(file);

%Find start in UTC
startutc=local2utc(start);
startutc=round(startutc);
dayzero=floor(start);
utczero=local2utc(dayzero);

rawdata=double(rawdata);
%Find sequence of data assumed consecutive
[nr,nc]=size(rawdata);
nt=floor(nr/fs);
stoputc=startutc+nt;
hours=nr/(fs*3600);

% nr=nt*fs;
% rawdata=rawdata(1:nr,:);

%Timestamps in UTC and miiliseconds
timeunit='ms';
tunit=1000;
timezone='UTC';
isutc=true;

seq=(1:nt)';
utc=startutc+seq;
d=utc2local(utc);
local=86400*(d-dayzero);    
t=utc-utczero;    
if local==t
    local=[];
end

t0=round(tunit*(startutc-utczero));

info.timezone=timezone;
info.timeunit=timeunit;
info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.utczero=round(tunit*utczero);
info.times=round(tunit*t);
info.local=round(tunit*local);

info.sampleperiod=T;
info.vitalfrequency=vfs;
info.startutc=round(tunit*startutc);
info.stoputc=round(tunit*stoputc);
info.start=datestr(start,31);
info.hours=hours;
        
%Scaling factorf
if length(fac)>1
    rawdata=fac(2)*rawdata+fac(1);
end

%Extra hard-coded scaling factors for oversampled vital sign waveforms
rawdata(:,3)=100*rawdata(:,3);
rawdata(:,4)=250*rawdata(:,4);

scale=1/fac(2);
offset=fac(1);
%block=NaN;

for i=1:nv
    data(i,:).name=info.name{i};
    data(i).fixedname=info.fixedname{i};        
    
    data(i).x=[];
    data(i).nx=0;
    data(i).fs=[];    
    data(i).raw=true;    
    data(i).t=[];

    if i<=nc
        data(i).x=rawdata(:,i);        
        data(i).fs=fs;
    else        
        data(i).x=downsample(rawdata(:,i-2),fs);        
        data(i).fs=1;
    end    
    data(i).nt=nt;    
    data(i).index=[1 nt];        
    data(i).T=T;
    data(i).block=data(i).fs;
    data(i).scale=scale;
    data(i).offset=offset;        
end
info.alldata=data;

end

function [rawdata,start,startutc,id]=getrawdatdata(file)
%function [rawdata,start,id]=getrawdatdata(file)
%
% file = input .dat file
%
% rawdata = matrix with raw signal data
% start - start time in Matlab format (from file name)
% id - patient id (from file name)

[~,root]=fileparts(file);

rawdata=[];

fid=fopen(file);
if fid>0
    rawdata=fread(fid,[4 inf],'int16','ieee-be')';
    fclose(fid);
end
%Get start date and id from filename
id=NaN;
start=NaN;

nr=length(root);
j=findstr('_',root);
if isempty(j)
    str=root;
else
    j1=j(1);
    str=root(1:(j1-1));    
end
try
    id=sscanf(str,'%d');
end
if length(j)>1
    str=root((j1+1):end);
    try
        start=datenum(str,'mmddyyyy_HHMMSS');
    end
end

end

function utc=local2utc(d,off)
%function utc=local2utc(d,off)
%
%d      local date in Matlab format
%
%utc    date in UTC format

%Eastern time zone default
if ~exist('off','var'),off=5*3600;end

dv=datevec(d);
y=dv(:,1);
wd=15-weekday(datenum(y,3,1)-1);
d1=datenum(y,3,wd,2,0,0);    
wd=8-weekday(datenum(y,11,1)-1);
d2=datenum(y,11,wd,1,0,0);
if d>=d1&&d<=d2
    off=off-3600;
end

%Convert time to UTC local time
utc=86400*(d-datenum(1970,1,1));

%GMT time
utc=utc+off;

end