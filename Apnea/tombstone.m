function [p,pt,pgood,hrf1,hrf2,x,xt]=tombstone(resp,respt,qt,qb,fs)
%function [p,pt,pgood,hrf1,hrf2,x]=tombstone(resp,respt,qt,qb,fs)
%
% resp chest impedance waveform
% respt timestamp for chest impedance
% qt times of detected heartbeats
% qb beat number of detected heartbeats
% fs sampling freauency for interpolated signal (default=60Hz)
%
% p apnea probability (tombstones)
% pt apnea probability timestamps
% pgood flag for no missing data
% hrf1 heart rate filtered signal
% hrf2 doubly filtered normalized signal
% x interpolated chest impedance signal
% xt timestamps for interpolated chest impedance signal

%Find time range
c1=round(fs*min(respt));
c2=round(fs*max(respt));
%xt=(c1:c2)'/fs;
xt=(c1:c2)';
yt=round(fs*respt);
%Interpolate to get consecutive data
[x,xt,xna]=naninterp(resp,yt,xt);
xt=xt/fs;

%Calculate envelope
[bhi,ahi]=butter(3,0.4/fs*2,'high');
[blo,alo]=butter(3,1/400*2/fs,'low');
xhi=filtfilt(bhi,ahi,x); 
env=filtfilt(blo,alo,abs(xhi)); 

%Find QRS detection in CI window
tmin=min(xt);
tmax=max(xt);
qsub=qt>=tmin&qt<=tmax;
qsub=qsub&qb>0;
qt=qt(qsub);
qb=qb(qsub);

%Heart rate filter
if ~isempty(qt) % Handle the situation where there is no ekg signal
    ns=30;
    hrf1=wmhrfilt(x,xt,qt,qb,ns);

    %Doubly filtered normalized signal
    hrf2=filtfilt(bhi,ahi,hrf1)./env;
else
    x = x./env;
end

%Four samples per second
ps=4;
p1=ceil(ps*xt(1));
p2=ceil(ps*xt(end));
pt=(p1:p2)'/ps;
dt=2;
if ~isempty(qt)  % Handle the situation where there is no ekg signal
    [p,psd,nx]=wmaprob(hrf2(~xna),xt(~xna),pt,dt);
else
    [p,psd,nx]=wmaprob(x(~xna),xt(~xna),pt,dt);
end
dtn=dt*fs;
pgood=nx>=(dtn*0.9); % At least 90% of the data in the two second window cannot be nans

end

function [y,yt,ynew,hy,ht,hx,hz,hb]=wmhrfilt(x,xt,qt,qb,ns)
%function [y,yt,hy,ht,hx,hz]=wmhrfilt(x,xt,qt,qb,ns)
%
% x original CI signal
% xt CI time stamps in seconds
% qt times of deteted beats
% qb deteted beat number
% ns number of samples per beat
%
% y  flltered CI (heart rate artifacts removed)
% yt flltered CI time stamps in seconds
% hy heart beat sampled flltered CI 
% ht heart beat sampled flltered CI time stamps in seconds
% hx heart beat sampled CI
% hz heart beat sampled heart rate artifact
% hb heart beat numbers 

if ~exist('ns','var'),ns=30;end

y=x;
yt=xt;

%Find good input and time range
xgood=~isnan(x);
x(~xgood)=0;

%Find times of equally spaced beat samples
bmin=min(qb);
bmax=max(qb);
hb=(bmin:(1/ns):bmax)';
ht=interp1(qb,qt,hb);

%Sample input signal by beat
hx=interp1(xt,x,ht);
 
% ht=naninterp(qt,qb,hb);
% hx=naninterp(x,xt,ht);

%Filter out integer harmonics
f=2*[1 2 3]'/ns;
bw=2*.1/ns;
[hy,hz]=filtfreqs(hx,f,bw);

%Resample by time over range with detected beats

ysub=yt>=ht(1)&yt<=ht(end);
y(ysub)=interp1(ht,hy,yt(ysub));
y(~xgood)=NaN;

%Reset filtered signal to original for missing QRS gaps
j=find(diff(qt)>10);
ynew=true(length(y),1);
for i=1:length(j)
    k=j(i);
    t1=qt(k);
    t2=qt(k+1);
    jj=yt>=t1&yt<=t2;
    ynew(jj)=0;
end
y(~ynew)=x(~ynew);

end

function [y,z]=filtfreqs(x,f,bw)
%function [y,z]=filtfreqs(x,f,bw)
%
% x input signals
% f frequencies to remove
% bw bandwith of filters
%
% y output with frequencies removed
% z output with only frequencies 

n=length(x);
y=zeros(n,1);
z=zeros(n,1);
nf=length(f);
y=x;
for i=1:nf
    W=f(i)+[-bw bw]/2;
    [b,a]=butter(1,W,'stop');
    y=filtfilt(b,a,y); 
    [b,a]=butter(1,W,'bandpass');
    z=z+filtfilt(b,a,x);
end

end

function [p,psd,nx]=wmaprob(x,xt,pt,dt)
%function [p,psd]=wmaprob(x,xt,pt,dt)
%
% x     input chest impedance signal
% xt    timestamps of input chest impedance signal
% pt    timestamps to calculate probability
% dt    window to calculate SD (default 2 seconds)
%
% p     apnea probability
% psd   SD of input signal over time window
% nx    number of input signal observations in time window

if ~exist('dt','var'),dt=2;end

x=double(x(:));
n=length(x);
nt=length(pt);

%Find indices for each window

d=dt/2;
w=[-d d];
[w1,w2]=findwindows(pt,[-d d],xt);

psd=NaN*ones(nt,1);
nx=zeros(nt,1);

for i=1:nt
    j1=w1(i);
    if isnan(j1),continue,end
    j2=w2(i);    
    if isnan(j2),continue,end
    if j2<j1,continue,end
    xx=x(j1:j2);        
    nx(i)=length(xx);
    psd(i)=std(xx);        
end

beta=12;
sigma=0.44;
p=1./(1+exp(beta*(psd-sigma)));

end
