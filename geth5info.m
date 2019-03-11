function [info,name,data]=geth5info(file)
%function info=getfileinfo(file)
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
info.fixedname=fixedname(name);
n=length(name);

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

startutc=0;
try
    startutc=h5readatt(file,'/','Start Time');
end

if isutc
    if isnan(dayzero)
        utczero=double(startutc/tunit);
        dayzero=floor(utc2local(utczero));
    end
end

%Get timestamps for all datasets and correct global times
[data,t,T]=geth5time(file,data,T);

info.originaltimes=t(:,2);
t=t(:,1);
local=[];
if isutc
    if isnan(dayzero)
        utczero=double(startutc/tunit);
        dayzero=floor(utc2local(utczero));
    end    
    utczero=round(tunit*local2utc(dayzero));        
    d=utc2local(t/tunit)-dayzero;
    t=t-utczero;    
    local=round(86400*tunit*d);
    if local==t
        local=[];
    end
end

if isnan(dayzero),dayzero=0;end
info.dayzero=dayzero;
info.utczero=utczero;
info.times=t;
info.local=local;
info.sampleperiod=T;
vfs=tunit/T;
info.vitalfrequency=vfs;

%Find root attributes for file

stoputc=0;
start='';
stop='';

layout=NaN;
source='';

try
    startutc=h5readatt(file,'/','Start Time');
end

try
    start=h5readatt(file,'/','Start Date/Time');
end

try
    stoputc=h5readatt(file,'/','End Time');
end

try
    stop=h5readatt(file,'/','End Date/Time');
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

hours=(stoputc-startutc)/(3600*tunit);
info.startutc=startutc;
info.stoputc=stoputc;
info.start=start;
info.stop=stop;
info.hours=hours;
info.layout=layout;
info.source=source;

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

info.datasets=data;

end

function [scale,offset]=scalefactor(file,dataset,layout)

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

%Find cal if not in file
if isempty(cal)
    if ~isempty(scale)
        cal=zeros(1,4);
        cal(1)=offset;
        cal(2)=cal(1)-1/scale;
        cal(4)=1;
    end
end

%Convert calibration vector used for BedMaster data to scaling factor 
%Cal = “Cal Lo, Cal Hi, Grid Lo, Grid Hi”
% The Cal and Grid values are used in a couple of scaling tags as well:
%Scale = (Cal Hi – Cal Lo) / (Grid Hi – Grid Lo)
%Scaled_data = Cal Lo + (Raw Sample – Grid Lo) * Scale *-1
%If Cal Hi is NaN then Scale = -0.025

%Use cal to find scale factor if stll empty
if isnan(scale)   
    if length(cal)>=4
%        fac(2)=-(cal(2)-cal(1))/(cal(4)-cal(3));
        scale=-(cal(4)-cal(3))/(cal(2)-cal(1));        
        offset=cal(1)-scale*cal(3);
    end
end    

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
