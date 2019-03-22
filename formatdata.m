function [xdata,xt,xname,t]=formatdata(data,info,tformat,dformat,rawflag)
%function [xdata,xt,xname,t]=formatdata(data,info,tformat,dformat,rawflag)
%
%data       structure with data values and timestamps
%           or cell array/single string with dataset names
%info       structure with file attributes 
%tformat    format/units of timestamps 
%           0=> milliseconds since day zero (default)
%           1=> days since day zero
%           2=> date in Matlab format
%           3=> date in UTC milliseconds format
%dformat    format of data output 
%           0=> single vector and time stamps (default)
%               or matrix with unique time stamps 
%           1=> structure format 
%           2=> long two-column matrix with vital sign number and value
%rawflag    0/false => make double precision and scale (default)
%           1/true => keep data in original raw unscaled format (e.g. short)

%xdata      data vector or matrix (dformat=0)
%           data structure (dformat=1)           
%           data column number / value pairs (dformat=2)
%xt         time stamps for rows of data matrix or global timestamps otherwise
%xname      names for structure element, matrix columns or column numbers
%t          global timestamps

if ~exist('info','var'),info=[];end
if ~exist('tformat','var'),tformat=0;end
if ~exist('dformat','var'),dformat=0;end
if ~exist('rawflag','var'),rawflag=0;end
rawflag=rawflag>0;

if isstruct(data)
    xdata=data;    
else
    xname=data;
    data=getfiledata(info,xname);
end

xdata=data;
%Default values
tunit=1000;
dayzero=0;
timezero=0;
t=[];
isutc=true;

if isfield(info,'times')
    t=info.times;
end    
xt=t;
if isfield(info,'tunit')
    tunit=info.tunit;
end
if isfield(info,'dayzero')
    dayzero=info.dayzero;
end
if isfield(info,'timezero')
    timezero=info.timezero;
end
if isfield(info,'isutc')
    isutc=info.isutc;
end    

%Find dataset names
n=length(xdata);
xname=cell(n,1);
for i=1:n
    if isfield(data,'name')
        xname{i}=data(i).name;
    else
        xname{i}=['Column ',num2str(i)];
    end
end

%Put global time stamps for each data point into structure

for i=1:n
    tt=data(i).t;
    seq=[];
    index=[];
%     if isfield(data,'seq')
%         seq=data(i).seq;
%     end

    if isfield(data,'index')
        index=data(i).index;
    end
    if size(index,2)>1    
        j1=index(:,1);
        j2=j1+index(:,2)-1;
        for k=1:length(j1)
            j=(j1(k):j2(k))';
            seq=[seq;j];
        end
    end    
    if ~isnan(t)
        if ~isempty(seq)
            tt=t(seq);
        end       
    end
    data(i).t=tt;
    nt=length(tt);
%Make data double precision and scale if requested    
    x=data(i).x;    
    if ~rawflag&&data(i).raw==1
        x=double(x);
        scale=data(i).scale;
        if ~isnan(scale)
            if scale~=1
                x=x/double(scale);
            end
        end
        offset=data(i).offset;
        if ~isnan(offset)
            if offset~=0           
                x=x-double(offset);
            end
        end
        data(i).raw=false;
        data(i).x=x;
    end
    nx=length(x);    
    if nx==0,continue,end        
    if nt~=nx
        block=data(i).block;
        if block==nx/nt
            fs=data(i).fs;
            dt=tunit/fs;            
            bt=dt*(-block+(1:block)');    
            tt=ones(block,1)*tt'+bt*ones(1,nt);
            tt=tt(:);
        end
    end
    data(i).t=tt;
end

%Structure output
xdata=data;
xt=t;

if dformat~=1
    x=[];
    xt=[];
    c=[];        
    for i=1:n
        nx=length(data(i).x);    
        if nx==0,continue,end            
        xx=data(i).x;
        tt=data(i).t;    
        nt=length(tt);    
        if nt~=nx,continue,end
        c=[c;i*ones(nx,1)];
        x=[x;xx];    
        xt=[xt;tt];
    end
end

%Matrix output
if dformat==0
    if n==1
        xdata=x;
    else        
        [xt,~,r]=unique(xt);
        nt=length(xt);
        xdata=NaN*ones(nt,n);
        for i=1:n
            j=c==i;
            xdata(r(j),i)=x(j);
        end
    end
end

%Long matrix output
if dformat==2
    xdata=[c x];    
end

%Format timestamps
tscale=NaN;    
toffset=NaN;
if length(tformat)==2
    tscale=tformat(1);
    toffset=tformat(2);
    tformat=NaN;
end

%Day units
day=86400*tunit;

if tformat==1
    tscale=day;
end

if tformat==2    
    tscale=day;        
    toffset=dayzero;
end

if tformat==3
    if isutc
        toffset=timezero;
    end
end

if isnan(tscale)
    tscale=1;
end
if isnan(toffset)
    toffset=0;
end

if tscale~=1
    t=t/tscale;
    xt=xt/tscale;
    if isstruct(xdata)
        for i=1:n
            xdata(i).t=xdata(i).t/tscale;
        end
    end
end
if toffset~=0
    t=toffset+t;    
    xt=toffset+xt;
    if isstruct(xdata)
        for i=1:n
            xdata(i).t=toffset+xdata(i).t;
        end
    end    
end    
