function [x,xt,fs,start,data,name,fac]=getwavedataold(file,name,window,fac,dmax)
%function [x,xt,fs,start,data,name,fac]=getwavedata(file,name,window,fac)
%
%file    character=>hdf5file to retrieve dataset structure
%        structure=>data already retrieved
%name    name of waveform dataset
%%window time window to retrieve (empty=default => all)
%        start=window(1)
%        stop=window(2)
%fac     scaling factor (fac=1 => no scaling)
%dmax    max drift to be in same group (default 1 second)
%
% x      waveform data
% xt     timestamps in integer samples at specified frequency
% fs     frequency in Hz
% start  start time 
% data   structure with dataset info


if ~exist('fac','var'),fac=[];end
if ~exist('window','var'),window=[];end
if ~exist('name','var'),name=cell(0,1);end
if ~exist('dmax','var'),dmax=1;end

if ischar(name)
    name={name};
end
if length(name)>1
    name=name{1};
end
if isstr(file)
    data=gethdf5datanew(file,name,window);
else
    data=file;
    name=data.name;
end
x=[];
xt=[];
fs=[];
if isempty(data),return,end

x=double(data.x); 
data.x=[];

%Convert to natural units if requested
if isempty(fac)
    fac=data.scalefac; 
end
if length(fac)==1
    if fac~=1
        x=x*fac;
    end
end

if length(fac)>1
    x=fac(2)*x+fac(1);
end

block=double(data.block);
fs=double(data.fs);
start=double(data.start);
dt=data.T;
tt=double(data.t)-start+dt;
tunit=data.tunit;
if rem(dt,1)==0
    tunit=1;    
end
if dt<tunit
    tunit=1;
end
    
%Correct for jitter

[t,d]=nojitter(tt,dt,tunit);

%Find blocks of consecutive data and correct block times for drift

[bt,g,m,d]=nodrift(t,d,dt,dmax);

%Find individual sample numbers for waveforms

if block>1
    [xt,t0]=wavesample(bt,g,m,block,dt);
    [x,xt]=noskip(x,xt);    
else
    xt=bt;
    t0=bt(1);
end

if nargout<4
    xt=start+t0+xt/fs;
end

%Add intermediate results to data structure if requested

if nargout<5,return,end
% data.xna=xna;
% data.xnew=xnew;
data.tt=tt;
data.ct=t;
data.bt=bt;
data.d=d;
data.g=g;
data.m=m;

end

function [y,ys,ynew]=noskip(x,xs)
% x      waveform data
% xs     integer samples
%
% y      new waveform data with skips of one sample interpolated
% ys     new integer samples
% ynew   logical variable for interpolated values

nx=length(x);

%Find all skips of one sample
d=find(diff(xs)==2);
nd=length(d);
ny=nx+nd;
y=NaN*ones(ny,1);
ys=NaN*ones(ny,1);
ynew=false(ny,1);

%Fill in gaps with average value of neighboring points
s1=1;
for i=1:nd
    s2=d(i);
    s=xs(s2);    
    j=(s1:s2)';
    s1=s2+1;
    k=j+(i-1);
    y(k)=x(j);
    ys(k)=xs(j);
    k2=k(end)+1;
    y(k2)=(x(s2)+x(s1))/2;
    ys(k2)=s+1;
    ynew(k2)=1;
end
j=(s1:nx)';
k=j+nd;
y(k)=x(j);
ys(k)=xs(j);

end

function [xs,start,fs,xt,t1,s1]=wavesample(t,g,m,block,dt)
%function [xt,bt,m]=nodrift(t,g,dt,block)
%
%g      group of consecutive data
%block  block of data at each time stamp
%
%xt     increasing sample numbers
%bt     increasing block times with no drift
%m      actual time between samples for each group

start=t(1);
n=length(t);
ng=max(g);
if ~exist('block','var'),block=1;end
if ~exist('dt','var'),dt=1;end
if ~exist('m','var'),m=ones(ng,1);end

fs=block/dt;

N=n*block;
xt=NaN*ones(N,1);
t1=NaN*ones(ng,1);
s1=NaN*ones(ng,1);
xs=NaN*ones(N,1);
for i=1:ng
    j=find(g==i);
    j1=j(1);
    t1(i)=t(j(1));
    s1(i)=round(fs*(t1(i)-start));    
    if j1>1
        if s1(i)<xs(j1-1)+1
            s1(i)=xs(j1-1)+1;            
            t1(i)=start+s1(i)/fs;
        end
    end
    j2=j(end);
%Indices of full signal     
    k1=j1*block;
    k2=j2*block;    
    k=((k1-block+1):k2)';
    d=m(i)*(k-k1);
    xt(k)=t1(i)+d/block;
    xs(k)=s1(i)+round(d/dt);
end        

end

function [t,d,st]=nojitter(t,dt,tunit)
%function [t,d,st]=nojitter(t,dt,tunit)
%
%t      original time stamps
%dt     target time between samples
%
%t      corrected times
%d      cumulative jitter
%st     ideal times without jitter

if ~exist('dt','var'),dt=1;end
if ~exist('tunit','var'),tunit=1;end

nt=length(t);
st=t(1)-dt+(1:nt)'*dt;
ds=t-st;
d=cummin(ds,'reverse');
td=d-ds;
t=t+td;
if tunit==1,return,end
if rem(dt,tunit)~=0
    t=t-tunit/2;
end
t=tunit*round(t/tunit);    

%t=t(1)-dt+(1:length(t))'*dt+cummin(t-(1:length(t))'*dt,'reverse');

end

function [t,g,m,d]=nodrift(t,d,dt,dmax)
%function [xt,bt,m]=nodrift(t,g,dt,block)
%
%t      original time stamps (in seconds)
%d     original drifts
%dt     target time between samples (default=1 second)
%dmax   max drfit to be in same group (default 1 second)
%
%t      increasing times with no drift
%g      group of consecutive data
%m      actual time between samples for each group

nt=length(t);
if ~exist('dt','var'),dt=1;end
if ~exist('g','var'),g=ones(nt,1);end
if ~exist('dmax','var'),dmax=1;end

%Find blocks of consecutive data
[g,d]=driftgroups(d,dmax);

n=max(g);
m=dt*ones(n,1);

for i=1:n
    j=find(g==i);
    j1=j(1);
    t1=t(j1);
    j2=j(end);
    t2=t(j2);
    nn=j2-j1;
    tt=t1+dt*(j-j1);
    dd=t2-tt(end);
%Actual time difference between samples if too much drift       
    if dd>dmax
        m(i)=(t2-t1)/(j2-j1);
        tt=t1+m(i)*(j-j1);        
    end
    t(j)=tt;
end

end

function [g,d]=driftgroups(d,dmax)
%function [d,g]=driftgroups(d)
%
%d     original drifts
%dmax  max drfit to be in same group (default 1 second)
%
%g     group of consecutive data
%d     corrected drifts


if ~exist('dmax','var'),dmax=1;end

n=length(d);
g=ones(n,1);
ud=unique(d);
nd=length(ud);
gap=find(diff(ud)>dmax);
ng=length(gap)+1;

for i=1:ng
    if i<ng
        k2=gap(i);
    else
        k2=nd;
    end    
    if i==1
        k1=1;        
    else
        k1=gap(i-1)+1;
    end
    d1=ud(k1);
    d2=ud(k2);    
    k=find(d>=d1&d<=d2);
    g(k)=i;
    dd=d(k);    
    if length(dd)<3,continue,end
    j=k(dd==dd(1));
    if length(j)==1
        d(j)=d(j+1);
    end
    j=k(dd==dd(end));    
    if length(j)==1   
        d(j)=d(j-1);
    end
end    

end

