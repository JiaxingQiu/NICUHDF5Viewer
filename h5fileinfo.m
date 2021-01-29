function [info,name,data]=h5fileinfo(file)
%function [info,name,data]=h5fileinfo(file)
%
%file       hdf5 file
%
%info       structure with time stamps and dataset attributes/names
%name       name of datasets
%data       stucture with dataset attributes and timestamps

info.file=file;

%Get names for all all datasets
name=datanames(file,'/','/data');
info.name=name;

%Find fixed names for all all datasets
n=length(name);
fixedname=findfixedname(name);

ecgleads={'ECGI','ECGII','ECGIII'}';
nleads=length(ecgleads);

% Find all ecg signals with and without fixed ecg lead name
ecg=false(n,1);
lead=zeros(n,1);
wave=find(startsWith(name,'/Waveforms/'));
nw=length(wave);
leads=(1:nleads)';
for i=1:nw
    j=wave(i);    
    k=strmatch(fixedname{j},ecgleads,'exact');    
    if ~isempty(k)
        ecg(j)=1;
        lead(j)=k;
        leads(leads==k)=[];
    else
        ecg(j)=contains(name{j},'ECG');
    end
end

% Find other ecg signals without fixed ecg name and assign them possibly arbitrary lead numbers
nolead=find(ecg&lead==0);
while ~isempty(nolead)&&~isempty(leads)
    j=nolead(1);
    k=leads(1);
    fixedname{j}=ecgleads{k};
    nolead(1)=[];
    leads(1)=[];
end

info.fixedname=fixedname;

%Create data structure shell
data=[];
for i=1:n    
    data(i,:).name=name{i};
    data(i).fixedname=info.fixedname{i};    
    data(i).x=[];
    data(i).nx=0;
    data(i).fs=[];    
    data(i).raw=true;    
    data(i).t=[];
    data(i).nt=0;    
    data(i).index=[];   
    data(i).T=NaN;
end

%Timestamps and sample period assumed in ms for now
timeunit='ms';
tunit=1000;

%Default values
timezone='UTC';
dayzero=NaN;
utczero=0;
T=NaN;

try
    timezone=h5readatt(file,'/','Timezone');
end

% try
%     timeunit=h5readatt(file,'/','Time Unit');
% end

try
    dayzero=h5readatt(file,'/','Day Zero');
end

isutc=strcmp(timezone,'UTC');

info.timezone=timezone;
info.timeunit=timeunit;
info.isutc=isutc;
info.tunit=tunit;

%See if there is root sample period attribute
try
    T=h5readatt(file,'/','Sample Period (ms)');
end
T=double(T);

start=0;
try
    start=h5readatt(file,'/','Start Time');
end

stop=0;
try
    stop=h5readatt(file,'/','End Time');
end

%Get timestamps for all datasets
[data,T]=h5datatime(file,data,T);

%Find time zero = midnight local time prior to start time
if isutc
    if isnan(dayzero)
        utczero=double(start/tunit);
        dayzero=floor(utc2local(utczero));
    end
    utczero=round(tunit*local2utc(dayzero));
end

source='';

try
    source=h5readatt(file,'/','Source Reader');
end

globaltime=~strcmp('TDMS',source);

%Get global times and fix jitter
%
local=[];
info.globaltime=globaltime;
info.originaltimes=[];
t=[];
if globaltime
    [data,t]=fixtime(data,T);
    if size(t,2)>1
        info.originaltimes=t(:,2);
        t=t(:,1);
    end
else
    data=indexdata(data);
    t=double((start:T:stop)');
    info.originaltimes=t;    
end

%Offset times by UTC time zero if UTC file
%Find local global times in case of time change
if isutc
    if ~isempty(t)  
        d=utc2local(t/tunit)-dayzero;
        t=t-utczero;    
        local=round(86400*tunit*d);
        if local==t
            local=[];
        end
    end
    if ~globaltime    
        for i=1:length(data)
            tt=data(i).t;
            if ~isempty(tt)
                data(i).t=tt-utczero;
            end
        end
    end    
end

if isnan(dayzero),dayzero=0;end
info.dayzero=dayzero;
info.datezero=datestr(dayzero,31);
info.timezero=utczero;
info.times=t;
info.local=local;
info.sampleperiod=T;
vfs=tunit/T;
info.vitalfrequency=vfs;

%Find root attributes for file

startdate='';
stopdate='';

layout=NaN;
source='';

% try
%     start=h5readatt(file,'/','Start Time');
% end

try
    startdate=h5readatt(file,'/','Start Date/Time');
end

try
    stopdate=h5readatt(file,'/','End Date/Time');
end

try
    layout=h5readatt(file,'/','Layout Version');
end

if iscell(layout)
    layout=layout{1};
end
if ischar(layout)
    try
        layout=str2num(layout(1));
    end
end

try
    source=h5readatt(file,'/','Source Reader');
end

hours=(stop-start)/(3600*tunit);
info.start=start;
info.stop=stop;
info.startdate=startdate;
info.stopdate=stopdate;
info.hours=hours;
info.layout=layout;
info.source=source;

%Add data and atributes from HDF5 file to the structure
n=length(data);    
for i=1:n    
    
    dataset=data(i).name;    
    dgroup=[dataset,'/data'];
    
%Set default values    
    x=[];
    raw=true;
    fs=[];
    block=[];
    xsize=[0 0];
    try
        xinfo=h5info(file,dgroup);
        xsize=xinfo.Dataspace.Size;
    end
    
    nx=length(x);
    nt=data(i).nt;
   
%Find data in window 
    
    try  
        block=h5readatt(file,dataset,'Readings Per Sample');
    end
    
    if isempty(block)
        block=max(xsize)/nt;
    end

    try
        fs=h5readatt(file,dataset,'Sample Frequency (Hz)');
    end
    
    block=double(block);
    
    if rem(block,1)~=0,block=NaN;end
    
    if isempty(fs)
        fs=1000*block/T;
    end
    
    [scale,offset]=scalefactor(file,dataset,layout);
    
%    data(i).xsize=xsize;        
    data(i).x=x;    
    data(i).nx=nx;
    data(i).raw=raw;
    data(i).fs=fs;    
    data(i).block=block;
    data(i).scale=scale;
    data(i).offset=offset;    

end

info.alldata=data;

end

function [scale,offset]=scalefactor(file,dataset,layout)
%
% Find scale and offset for specified dataset

if ~exist('layout','var'),layout=NaN;end

dgroup=[dataset,'/data'];

scale=NaN;
offset=NaN;
cal=[];

try
    scale=h5readatt(file,dgroup,'Scale');
end

%For layout version 3, scale is simply a multiplicative factor for the original value.
%To get the real value, you divide by scale. 
%For layout version 4.0, a real value of 1.2 is stored as 12 with a scale of 1, 
%where scale is stored as the power of 10, so to convert from 12 back to 1.2, you need to divide by 10^scale.
%Later in this code, when we are actually plotting the data, we divide by scale

if ~isnan(scale)
    scale=double(scale);
    if layout~=3
        scale=10^scale;
    end
end

try
    cal=h5readatt(file,dgroup,'Cal');        
end

%Convert calibration to numbers if necessary
if iscell(cal)
    cal=cal{1};
end
if ischar(cal)
    try
        cal=cell2mat(textscan(cal,'%f','Delimiter',','));
    end
end

%Convert calibration vector used for BedMaster data to scaling factor 
%Cal = “Cal Lo, Cal Hi, Grid Lo, Grid Hi”
% The Cal and Grid values are used in a couple of scaling tags as well:
%Scale = (Cal Hi – Cal Lo) / (Grid Hi – Grid Lo)
%Scaled_data = Cal Lo + (Raw Sample – Grid Lo) * Scale *-1
%If Cal Hi is NaN then Scale = -0.025

%Use cal to find scale factor if stll empty
if length(cal)>=4
    %        fac(2)=-(cal(2)-cal(1))/(cal(4)-cal(3));
    scale=-(cal(4)-cal(3))/(cal(2)-cal(1));        
    offset=cal(1)-cal(3)/scale;
end
%end    

%Find cal if not in file
% if isempty(cal)
%     if ~isnan(scale)
%         cal=zeros(1,4);
%         cal(1)=0;
%         cal(2)=1;
%         cal(3)=-scale*offset;
%         cal(4)=cal(3)-scale;
%     end
% end

end

function name=datanames(file,group,filter)
%function name=datanames(file,group,filter)
%
%file hdf5 file
%group group to find datasets
%filter datasets to find

if ~exist('group','var'),group='/';end
if ~exist('filter','var'),filter='';end
info=[];

if ~isempty(group)
    try
        info=h5info(file,group);    
    end
else
    try
        info=h5info(file);    
    end
end
name=cell(0,1);
if isempty(info),return,end
if ~isfield(info,'Datasets'),return,end
Datasets=info.Datasets;
if isfield(Datasets,'Name')
    n=0;
    for i=1:length(Datasets)
        Name=Datasets(i).Name;
        if isempty(Name),continue,end
        Name=[group,'/',Name];        
        if ~isempty(filter)
            j=findstr(filter,Name);
            if isempty(j),continue,end
            Name(j(1):end)=[];
        end
        n=n+1;
        name{n,1}=Name;
    end    
end

if ~isfield(info,'Groups'),return,end
if ~isfield(info.Groups,'Name'),return,end
ng=length(info.Groups);
for i=1:ng
    name1=datanames(file,info.Groups(i).Name,filter);    
    name=[name;name1];    
end

end

function [data,T]=h5datatime(file,data,T)
%function [data,T]=h5datatime(file,data,T)
%
%file       hdf5 file
%data       srtucture with name of datasets
%T          block period in milliseconds
%
%data       dataset structure with requested time stamps and attributes

if ~exist('T','var'),T=NaN;end

n=length(data);
name=cell(n,1);
if n==0,return,end

for i=1:n    
    dataset=data(i).name;    
    name{i}=dataset;
    
    tgroup=[dataset,'/time'];
    tsize=[0 0];
    try
        tinfo=h5info(file,tgroup);
        tsize=tinfo.Dataspace.Size;
    end
%    data(i).tsize=tsize;
    t=[];
    try
        t=h5read(file,[dataset,'/time']);
    end
    t=double(t);
    if size(t,2)>size(t,1)
        t=t';
        t=t(:,1);
    end
    nt=length(t);   
    data(i).t=t;
    data(i).nt=nt;
    data(i).T=T;
    if isnan(T)
        try
            data(i).T=h5readatt(file,dataset,'Sample Period (ms)');            
        end
    end
    data(i).T=double(data(i).T);
%Correct possible decreasing times
    if nt<2,continue,end
    dt=diff(t);
    if min(dt)>=0,continue,end
    t=max(cummax(t),t);
    data(i).t=t;        
    
end

if isnan(T)
    T=double(cat(1,data.T));
    [T,~,ic]=unique(T);    
    nT=length(T);
    if nT>1       
        nn=zeros(nT,1);
        for i=1:nT
            nn(i)=sum(ic==i);
        end
%         disp([T nn])
        [~,j]=max(nn);
        T=T(j);
    end
end

end

function data=indexdata(data)
%
%Add index to consecutive timestamps in data structure

n=length(data);

for i=1:n
    t=data(i).t;
    nt=length(t);
    if nt==0,continue,end
    T=double(data(i).T);
    t0=t(1);
    j=1+(t-t0)/T;
    if sum(rem(j,1)~=0)>0,continue,end
    data(i).t=t0;
    j1=min(j);
    j2=max(j);    
    k=find(diff(j)>1);
    if ~isempty(k)       
        j2=[j(k);j2];
        j1=[j1;j(k+1)];
    end
    index=[j1 j2-j1+1];
    data(i).index=index;
end

end