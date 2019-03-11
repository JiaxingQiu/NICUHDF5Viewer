function [xdata,xname,xt,t]=formatdata(data,info,tformat,dformat,rawflag)
%function [xdata,xname,xt,t]=formatdata(data,info,tformat,dformat)
%
%data       structure with data values and timestamps
%info       structure with file attributes 
%tformat    format/units of timestamps 
%           0=> milliseconds since day zero (default)
%           1=> days since day zero
%           2=> UTC in miiliseconds
%           3=> date in Matlab format
%           4=> local date in Matlab format (corrected for timechanges)
%           vector => global timestamps
%dformat    format of data output 
%           0=> matrix and time stamps 
%           1=> structure format (default)
%           2=> long two-column matrix with vital sign number and value
%rawflag    flag to keep data in original format
%           default=0/false => get double precision and scale

%x          data structure (structure format)
%           data matrix (matrix format)
%           data column number / value pairs (long format)
%xname      names for structure element, matrix columns or column numbers
%xt         time stamps for rows of data matrix or global timestamps otherwise

%t          global timestamps

if ~exist('info','var'),info=[];end
%if ~exist('tunit','var'),tunit=1000;end
if ~exist('tformat','var'),tformat=0;end
if ~exist('dformat','var'),dformat=1;end
if ~exist('rawflag','var'),rawflag=0;end
rawflag=rawflag>0;

%Default values
tunit=1000;
dayzero=0;
t=[];

if isfield(info,'times')
    t=info.times;
end    
if isfield(info,'tunit')
    tunit=info.tunit;
end
if isfield(info,'dayzero')
    dayzero=info.dayzero;
end

%Find global timestamps for requested format
if length(tformat)>1
    t=tformat;
    tformat=NaN;    
end

%In day units
d=double(t)/(86400*tunit);

if tformat==1
    t=d;
end

if tformat==2
    utczero=0;
    if isfield(info,'utczero')
        utczero=info.utczero;
    end    
    t=utczero+t;
end

if tformat==3    
    t=dayzero+d;
end

if tformat==4
    local=[];
    if isfield(info,'local')
        local=info.local;
    end        
    if ~isempty(local)
        d=double(local)/(86400*tunit);
    end
    t=dayzero+d;    
end

xdata=data;
xt=t;

%Find dataset names
n=length(data);
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
%     if isfield(data,'seq')
%         seq=data(i).seq;
%     end       
    if isfield(data,'index')
        index=data(i).index;
        j1=index(:,1);
        j2=j1+index(:,2)-1;
        for k=1:length(j1)
            j=(j1:j2)';
            seq=[seq;j];
        end
    end    
    if ~isnan(t)
        if ~isempty(seq)
            tt=t(seq);
        end       
    end    
    nt=length(tt);
    x=data(i).x;
    if ~rawflag&&data(i).raw
        x=double(x);
        scale=data(i).scale;
        if ~isnan(scale)        
            x=x/double(scale);
        end
        offset=data(i).offset;
        if ~isnan(offset)
            x=x-double(offset);
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
if dformat==1
    xdata=data;
    xt=t;
    return
end

%Single signal format
if dformat==0
    if n==1       
        xdata=data.x;
        xt=data.t;
        return
    end
end

%Put all data into long vectors 
x=[];
c=[];
xt=[];
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

%Long matrix output
if dformat==2
    xdata=[c x];    
    return
end
%Matrix output
[xt,~,r]=unique(xt);
nt=length(xt);
xdata=NaN*ones(nt,n);
for i=1:n
    j=c==i;
    xdata(r(j),i)=x(j);
end
