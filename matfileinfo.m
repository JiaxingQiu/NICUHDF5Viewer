function info=matfileinfo(file)
%function info=datfileinfo(file)
%
%file       .mat file with vital signs
%
%info       structure with dataset attributes/names

if ~exist('name','var'),name=cell(0,1);end
if ischar(name),name={name};end

isvital=endsWith(file,'_vitals.mat');

%Default values
%Timestamps in age and ms
timeunit='ms';
tunit=1000;
if isvital
    timezone='Age';
else
    timezone='Relative';
end
isutc=false;
dayzero=0;
timezero=0;
local=[];
vfs=.5;
T=2000;

info.file=file;

vname=cell(1,0);
vt=[];
vdata=[];
try
    load(file,'vname','vt','vdata');
end
nv=length(vname);
info.name=vname;
info.fixedname=fixedname(info.name);
nt=length(vt);
start=0;
stop=0;
if nt>0
    start=vt(1);
    stop=vt(nt);
end
hours=(stop-start)/3600;
days=hours/24;
info.timezone=timezone;
info.timeunit=timeunit;
info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.datezero=datestr(dayzero,31);
info.timezero=round(tunit*timezero);
info.times=round(tunit*vt);
info.local=round(tunit*local);
info.sampleperiod=T;
info.vitalfrequency=vfs;
info.start=round(tunit*start);
info.stop=round(tunit*stop);
info.datezero=datestr(dayzero,31);
info.startdate=datestr(dayzero+start/86400,31);
info.stopdate=datestr(dayzero+stop/86400,31);
info.hours=hours;
info.days=days;

for i=1:nv
    data(i,:).name=info.name{i};
    data(i).fixedname=info.fixedname{i};
    x=vdata(:,i);
    j=find(~isnan(x));
    j1=min(j);
    j2=max(j);    
    k=find(diff(j)>1);
    if ~isempty(k)       
        j2=[j(k);j2];
        j1=[j1;j(k+1)];
    end
    index=[j1 j2-j1+1];    
    x=x(j);
    data(i).x=x;
    data(i).nx=length(x);
    data(i).fs=vfs;    
    data(i).raw=true;    
    data(i).t=[];
    data(i).index=index;    
    data(i).T=T;
    data(i).block=1;
    data(i).scale=NaN;
    data(i).offset=NaN;        
end
info.alldata=data;
