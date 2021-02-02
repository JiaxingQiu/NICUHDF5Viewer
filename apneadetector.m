function [results,pt,tag,tagname,qrs] = apneadetector(info,lead,result_qrs)
% apneadetector uses the resp waveform to calculate the probability of apnea.
% If an EKG sig is selected & available, it uses the signal to filter out
% heartbeats from the chest impedance waveform.

%
% INPUT:
% info:        from getfileinfo - if empty, it will go get it
% lead:        value from 0 to 3 indicating lead of interest. 0 = no lead
%              default empty => all leads
% result_qrs:  result_qrs, if it exists, otherwise []
%
% OUTPUT:
% results:     probability of apnea
% pt:          UTC ms
% tag:         tags ready to be saved in the results file
% tagname:     tagnames ready to be saved in the results file
% qrs          structure with QRS detection results if new

% Add algorithm folders to path
if ~isdeployed
    addpath('..\Apnea')
    addpath('..\QRSDetection')
end

if ~exist('result_qrs','var'),result_qrs=[];end
if ~exist('lead','var'),lead=[];end
leadall=isempty(lead);

% disp('Read CI')
% tic
% Initialize output variables in case the necessary data isn't available
results = [];
pt = [];
tag = [];
tagname = [];
qrs=[];

% UTC milleseconds time format
tformat=3;
% structure data format
dformat=1;

% Load in the respiratory signal
[data,~,info] = getfiledata(info,'Resp');
[data,~,~] = formatdata(data,info,tformat,dformat);
% toc
if isempty(data) % if there is no chest impedance signal, give up
    return
end

% disp('Load QRS data')

% tic
resp = data.x;
respt = data.t;
CIfs = data.fs;

if round(CIfs,1)~=CIfs
    CIfs = 1/round(1/CIfs,3);
end

% Find the name of the result file

if isempty(result_qrs)  
    if isfield(info,'resultfile')
        resultfilename = info.resultfile;
        try
            load(resultfilename,'result_qrs')
        end            
    end    
end
nqrs=length(result_qrs);
if leadall,lead=[1 2 3]';end
% Calculate QRS if not in results file
if nqrs==0    
%     disp('QRS Detection')
%     tic
    nlead=length(lead);
    if nlead>0
        clear qrs
        for i=1:nlead      
            qrs1=qrsdetector(info,lead(i));
            if isempty(qrs1),continue,end
            nqrs=nqrs+1;
            qrs(nqrs,1)=qrs1;
            result_qrs(nqrs,1).qrs=qrs1;
        end
    end
%     toc
end        

%Find good qrs heartbeats for each lead

goodbeats=[];
try
    goodbeats=cat(1,result_qrs.qrs);
end
% for i=1:nqrs
%     qrs1=result_qrs(i).qrs;
%     goodbeats=[goodbeats;qrs1];
% end
nqrs=length(goodbeats);
keep=true(nqrs,1);
for i=1:nqrs
    goodbeats(i).qb=[];
    goodbeats(i).qgood=[];    
    if ~leadall      
        keep(i)=sum(lead==goodbeats(i).lead)>0;
    end
    if ~keep(i),continue,end
    qt=[];
    try
        qt=goodbeats(i).qt;
    end
    keep(i)=~isempty(qt);
    if ~keep(i),continue,end
    [qb,qgood]=qrsgood(qt/1000); % Needs seconds as an input
    goodbeats(i).qb=qb;
    goodbeats(i).qgood=qgood;    
    keep(i)=sum(qgood)>0;    
end
goodbeats=goodbeats(keep);

% Calculate the apnea probability

% disp('Calculate the apnea probability')

[p,pt,pgood]=tombstone(resp,respt/1000,goodbeats,CIfs); % Needs seconds as an input and returns seconds as an output 
pt = pt*1000; % convert seconds back to ms

% Output the apnea probability
results=p;

% disp('Apnea Tags')
%Set NaN's
p(~pgood)=0;

% tic
% Create apnea tags
[tag,tagname]=wmtagevents(p,pt);
% toc

end

function [p,pt,pgood]=tombstone(resp,respt,goodbeats,fs)
%function [p,pt,pgood]=tombstone(resp,respt,goodbeats,fs)
%
% resp          chest impedance waveform
% respt         timestamp for chest impedance
% goodbeats     structure with detected heartbeats
% fs            sampling freauency for interpolated signal (default=60Hz)
%
% p             apnea probability (tombstones)
% pt            apnea probability timestamps
% pgood         flag for no missing data

% hrf1          heart rate filtered signal
% hrf2          doubly filtered normalized signal
% x             interpolated chest impedance signal
% xt            timestamps for interpolated chest impedance signal

% disp('Find Envelope')

% tic
%Find time range
c1=round(fs*min(respt));
c2=round(fs*max(respt));
%xt=(c1:c2)'/fs;
xt=(c1:c2)';

%Interpolate to get consecutive data
[x,xt,xna]=naninterp(resp,round(fs*respt),xt);
xt=xt/fs;
xgood=~xna;

% Signal without NaNs
y=x(xgood);
yt=xt(xgood);

%Calculate envelope
[bhi,ahi]=butter(3,0.4/fs*2,'high');
[blo,alo]=butter(3,1/400*2/fs,'low');
xhi=filtfilt(bhi,ahi,y); % Amanda changed the x in this equation to y because filtfilt couldn't handle nan inputs
env=filtfilt(blo,alo,abs(xhi)); 
% toc

% Envelope without NaNs
% env=env(xgood); %Amanda commented this out because env already had the nans removed above with her change to the xhi equation

%Four samples per second % Amanda changed all calls to x and xt to y and yt to keep all indices on track
ps=4;
p1=ceil(ps*yt(1));
p2=ceil(ps*yt(end));
pt=(p1:p2)'/ps;
dt=2;
nt=length(pt);

tmin=min(yt);
tmax=max(yt);

%Find windows for apnea probability calculation

d=dt/2;
w=[-d d];
[w1,w2]=findwindows(pt,[-d d],yt);
w1=w1(~isnan(w1)); % Amanda added this to avoid nan errors in windowsd
w2=w2(~isnan(w2)); % Amanda added this to avoid nan errors in windowsd
nw=w2-w1+1;
dtn=dt*fs;
pgood=nw>=(dtn*0.9); % At least 90% of the data in the two second window cannot be nans

%Find apnea probability with no HR filter
psd=windowsd(y./env,w1,w2);

nqrs=length(goodbeats);

for i=1:nqrs

    qt=[];
    try
        qt=goodbeats(i).qt;        
    end

    if isempty(qt),continue,end
    qb=goodbeats(i).qb;    
    qt=qt/1000;
    qsub=qt>=tmin&qt<=tmax;
    qsub=qsub&qb>0;
    qt=qt(qsub);
    qb=qb(qsub);

    if isempty(qt),continue,end

    % disp('HR Filter')
    % tic
    %Heart rate filter
    ns=30;
    hrf1=wmhrfilt(y,yt,qt,qb,ns); % Amanda changed the x in this equation to y because filtfilt couldn't handle nan inputs
    %Doubly filtered normalized signal
    hrf2=filtfilt(bhi,ahi,hrf1);
    % Heart filtered signal without NaNs
    y=hrf2; %hrf2(xgood); Amanda changed this equation because wmhrfilt is being run with the nans removed
    % toc
    % disp('Apnea Probability')
    % tic
    psd1=windowsd(y./env,w1,w2);

    j=find(psd1>=0&~(psd1>psd));
    psd(j)=psd1(j);
    % toc

end

beta=12;
sigma=0.44;
p=1./(1+exp(beta*(psd-sigma)));

p(psd==0)=1;
p(psd==Inf)=0;
pgood(isnan(p))=0;

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

function [sd,nw]=windowsd(x,w1,w2)
%function [sd,nw]=windowsd(x,w1,w2)
%
% x     input signal
% w1    window start indice
% w2    window stop indice
%

% sd   SD of input signal over time window
% nw   number of input signal observations in time window

n=length(w1);
sd=NaN*ones(n,1);
nw=zeros(n,1);
for i=1:n
    j=(w1(i):w2(i))';
    if isempty(j),continue,end
    nw(i)=length(j);
    sd(i)=std(x(j));
end

% T2=[0;cumsum(x.^2)];
% T1=[0;cumsum(x)];
% 
% nw=w2-w1+1;
% good=find(nw>0);
% j2=w2(good);
% j1=w1(good);
% nw=nw(good);
% s1=T1(j2+1)-T1(j1);
% s2=T2(j2+1)-T2(j1);
% sxx=s2-(s1.^2)./nw;
% sd(good)=sqrt(sxx./(nw-1));
% 
end
