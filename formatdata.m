function [xdata,xt,xfs,xname,t]=formatdata(data,info,tformat,dformat,rawflag)
%function [xdata,xt,xname,t]=formatdata(data,info,tformat,dformat,rawflag)
%
%data       structure with data values and timestamps
%           or cell array/single string with dataset names
%info       structure with file attributes 
%
%tformat    format/units of timestamps 
%           0=> milliseconds since day zero (default)
%           1=> days since day zero
%           2=> date in Matlab format
%           3=> date in UTC milliseconds format
%
%dformat    format of data output 
%           0=> data matrix with time stamps (default)
%           1=> structure format 
%           2=> long 3-column matrix with timestamp row, vital sign column and value
%           -1=> data matrix with global time stamps
%
%rawflag    0/false => make double precision and scale (default)
%           1/true => keep data in original raw unscaled format (e.g. short)

%xdata      data matrix (dformat=0)
%           data structure (dformat=1)           
%           data column number / value pairs (dformat=2)
%xt         time stamps for rows of data matrix or global timestamps otherwise
%xfs        frequencies for structure elments or columns
%xname      names for structure element or columns
%t          global timestamps

xdata=[];
xt=[];
xfs=[];
xname=[];
t=[];

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

if isempty(data),return,end

xdata=data;
%Default values
tunit=1000;
dayzero=0;
timezero=0;
t=[];
isutc=true;
globaltime=true;

if isfield(info,'globaltime')
    globaltime=info.globaltime;
end    

if isfield(info,'times')
    t=info.times;
end    
if ~globaltime
    t=NaN;
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

%Find dataset frequencies and names
n=length(xdata);
xfs=ones(n,1);
xname=cell(n,1);
% Vitals signs that return as integers for consistency across sites
vname={'HR','Pulse','SPO2_pct'}';
xinteger=false(n,1);

for i=1:n
    if isfield(data,'name')
        xname{i}=data(i).name;
    else
        xname{i}=['Column ',num2str(i)];
    end
    if isfield(data,'fs')
        if isempty(data(i).fs)
            xfs(i) = NaN;
        else
            xfs(i)=data(i).fs;
        end
    end
    if isfield(data,'fixedname')    
        j=strmatch(data(i).fixedname,vname,'exact');
        if isempty(j),continue,end
        xinteger(i)=1;
    end
end

% Put timestamps and data in requested format into structure

%Three ways to put timestamps for each data point into structure
%
%Three ways of getting timestamps
%
%1) data.t          = []
%   data.index      = index into global timestamps 
%2) data.t          = time zero
%   data.index      = index of equally spaced consecutive times from time zero
%   data.T          = time between blocks
%3) data.t          = timestamps already found

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
% Convert index into sequence vector    
    if size(index,2)>1    
        j1=index(:,1);
        j2=j1+index(:,2)-1;
        for k=1:length(j1)
            j=(j1(k):j2(k))';
            seq=[seq;j];
        end
    end
    data(i).seq=seq;
%Don't need sequence any more if structure output
    if dformat==1
        data(i).seq=[];
    end
%Use global timestamps if they exist
    if ~isnan(t)
        if ~isempty(seq)
            tt=t(seq);
        end
    else
%Offset from time zero if it exists        
        if length(tt)==1
            t0=tt;
            T=double(data(i).T);            
            tt=t0+(seq-1)*T;
        end
    end
    data(i).t=tt;
    nt=length(tt);
%Make data double precision and scale if requested    
    x=data(i).x;    
    xclass=class(x);
    if ~rawflag&&data(i).raw==1            
        x=double(x);
%         if strcmp(xclass,'int16')
%             x(abs(x)>2^14)=NaN;
%         end
        if ~strcmp(xclass,'double')
            x(abs(x)>2^14)=NaN;
        end
        scale=data(i).scale;
        if ~isnan(scale)
            if scale~=1
                x=x/double(scale);
            end
        end
        offset=data(i).offset;
        if ~isnan(offset)
            if offset~=0           
                x=x+double(offset);
            end
        end
        data(i).raw=false;        
%        data(i).x=x;
    end
    if xinteger(i)
        x=round(x);
        x(x<=0)=NaN;
    end
    data(i).x=x;
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

%Find long output components if not structure output

if dformat==1      
    xdata=data;
    xt=t;
else
    x=[];
    xt=[];
    c=[];
    r=[];
    for i=1:n
        nx=length(data(i).x);    
        if nx==0,continue,end            
        xx=data(i).x;
        tt=data(i).t;
        seq=data(i).seq;
        nt=length(tt);    
        if nt~=nx,continue,end
        r=[r;seq];
        c=[c;i*ones(nx,1)];
        x=[x;xx];    
        xt=[xt;tt];
    end
end

%Matrix output
if dformat<=0
    if dformat==0
        [xt,~,r]=unique(xt);
    else
        xt=t;
    end
    nt=length(xt);
    xdata=NaN*ones(nt,n);
    for i=1:n
        j=c==i;
        xdata(r(j),i)=x(j);
    end
end

%Long matrix output
if dformat==2
    xdata=[r c x];    
end

%Format timestamps in requested format and time unit

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

%Default is no scaling or offset
if isnan(tscale)
    tscale=1;
end
if isnan(toffset)
    toffset=0;
end

%Scale timestamps if requested
if tscale~=1
    t=t/tscale;
    xt=xt/tscale;
    if isstruct(xdata)
        for i=1:n
            xdata(i).t=xdata(i).t/tscale;
        end
    end
end

%Offset timestamps if requestec
if toffset~=0
    t=toffset+t;    
    xt=toffset+xt;
    if isstruct(xdata)
        for i=1:n
            xdata(i).t=toffset+xdata(i).t;
        end
    end    
end    
