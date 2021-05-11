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
    fac=[ ];
end

%Timestamps in UTC and ms
timeunit='ms';
tunit=1000;
timezone='UTC';
isutc=true;

info.file=file;

%Hard code dat file names

name={'/Raw/ECG','/Raw/RESP','/Raw/SPO2','/Raw/HR'}';

%Add processed signals

name=[name;{'/Waveforms/ECG','/Waveforms/RESP','/VitalSigns/SPO2','/VitalSigns/HR'}'];

%Hard code waveform and vital sign frequency
wfs=200;
vfs=1;
T=1000;

%Scaling factors
%Signals 3 and 4 hard-coded
sf=[1;1;100;250;NaN;NaN;NaN;NaN];

%Frequencies
fs=[wfs*ones(6,1);vfs*ones(2,1)];

info.name=name;
info.fixedname=fixedname(name);

info.facfile=facfile;
info.fac=fac;

scale=1;
offset=0;

if length(fac)>1
    scale=1/fac(2);
    offset=fac(1);
end

nv=length(info.name);

%Get raw data and start date from file
[rawdata,start]=getrawdatdata(file);

%Find start in UTC
startutc=local2utc(start);
startutc=round(startutc);
dayzero=floor(start);
utczero=local2utc(dayzero);

%Find sequence of data assumed consecutive
[nr,nc]=size(rawdata);
nt=floor(nr/wfs);

%Get rid of incomplete blocks at the end
nr1=nt*wfs;
if nr1<nr
    rawdata=rawdata(1:nr1,:);
    nr=nr1;
end

stoputc=startutc+nt;
hours=nr/(wfs*3600);

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

stop=d(nt);
local=86400*(d-dayzero);
t=utc-utczero;    
t=round(tunit*t);
local=round(tunit*local);

if local==t    
    local=[];
% else
%     disp(sum(local~=t))
end

t0=round(tunit*(startutc-utczero));

info.timezone=timezone;
info.timeunit=timeunit;
info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.datezero=datestr(dayzero,31);
info.timezero=round(tunit*utczero);
info.times=t;
info.local=local;
% info.times=round(tunit*t);
% info.local=round(tunit*local);

info.sampleperiod=T;
info.vitalfrequency=vfs;
info.start=round(tunit*startutc);
info.stop=round(tunit*stoputc);
info.startdate=datestr(start,31);
info.stopdate=datestr(stop,31);
info.hours=hours;

%block=NaN;

%Raw signals
for i=1:nv
    data(i,:).name=info.name{i};
    data(i).fixedname=info.fixedname{i};    
    data(i).x=[];
    data(i).nx=0;        
    data(i).fs=fs(i);
    data(i).raw=false;    
    data(i).t=[];
    data(i).nt=nt;    
    data(i).index=[1 nt];        
    data(i).T=T;
    data(i).block=fs(i);
    data(i).scale=scale/sf(i);    
    data(i).offset=sf(i)*offset;        
    if ~isnan(sf(i))
        data(i).x=rawdata(:,i);
        data(i).raw=true;
    end       
end

rawdata=double(rawdata);
%Scaling factor
if length(fac)>1
    rawdata=fac(2)*rawdata+fac(1);
end

%Hard-coded scaling factors for oversampled vital sign waveforms
rawdata(:,3)=sf(3)*rawdata(:,3);
rawdata(:,4)=sf(4)*rawdata(:,4);

%Find individual waveforms and vital sign signals
ecg=rawdata(:,1);
resp=rawdata(:,2);

% spo2=downsample(rawdata(:,3),wfs);        
% hr=downsample(rawdata(:,4),wfs);        

[spo2,spo2good,hr,hrgood]=noisefilter(rawdata(:,3),rawdata(:,4));

clear rawdata

%Filter out high frequency noise in ECG waveform

[b,a]=butter(5,2*40/wfs,'low');
ecg=filtfilt(b,a,ecg);

%Filter out high frequency noise in RESP waveform
[b,a]=butter(5,2*5/wfs,'low');
resp=filtfilt(b,a,resp);

%Find SD for each second and identify low amplitude ECG outliers
amp=log(std(reshape(ecg(1:(wfs*nt)),wfs,nt))');
u=mean(amp(amp>-Inf));
s=std(amp(amp>-Inf));
amplow=u-3*s;
low=find(amp<amplow);
for i=1:length(low)
    j=wfs*(low(i)-1)+(1:wfs);
    ecg(j)=NaN;
    resp(j)=NaN;
end

%Find SPO2 and HR outliers
% hrgood=hr>40;
% uhr=mean(hr(hrgood));
% shr=std(hr(hrgood));
% Thr=min(80,uhr-4*shr);
% hrgood=hrgood&hr>Thr;
hr(~hrgood)=NaN;

% spo2good=spo2>40;
% uspo2=mean(spo2(spo2good));
% sspo2=std(spo2(spo2good));
% Tspo2=min(60,uspo2-4*sspo2);
% spo2good=spo2good&spo2>Tspo2;
spo2(~spo2good)=NaN;

data(5).x=ecg;
data(6).x=resp;
data(7).x=spo2;
data(8).x=hr;

for i=1:nv
    data(i).nx=length(data(i).x);
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
    rawdata=fread(fid,[4 inf],'*int16','ieee-be')';
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