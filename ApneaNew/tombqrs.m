function [qt,qb,qgood,x,xt]=tombqrs(x,xt,fs,t)
%function [qt,qb,qgood,x,xt]=tombqrs(x,xt,fs)
%
% x ECG waveform
% xt timestamp for ECG
% fs sampling frequency
% t  times for interpolated ECG (default = whole range)
%
% qt times of detected heartbeats
% qb beat number of detected heartbeats
% qgood flag for good heartbeats
% x interpolated EKG signal
% xt timestamps for interpolated EKG signal

if ~exist('t','var'),t=[];end

%Get rid of NaNs at beginning and end of the signal

n=length(x);
xgood=~isnan(x);
ngood=sum(xgood);
if ngood==0,return,end
if ngood<n
    j1=find(xgood,1);
    j2=find(xgood,1,'last');
    x=x(j1:j2);
    xt=xt(j1:j2);
    n=length(x);
end

%Resample signal to make consecutive

[x,xt]=nogaps(x,xt,fs);

%QRS detection
[q,sign,en_thres]=qrs_detect2(x,0.2,0.6,fs);
q=q(:);
nq=length(q);
qt=xt(q);

%Find good hearbeats and RR intervals
[qb,qgood,rr,rrt,drop]=qrsgood(qt);

if nargout<3
    qt=qt(qgood);
    qb=qb(qgood);
end

end

function [qb,good,rr,rrt,drop]=qrsgood(qt,dflag)

%function [good,rr,rrt,drop]=qrsgood(qt,hr,hrt,dflag)
%
%qt - time of detected beats in seconds
%dflag - flag for RR intervals to drop
%
%qb - beat number of good heartbeats
%good - heartbeats associated with good RR intervals
%rr - estimated RR intervals
%rrt - time for estimated RR intervals
%drop - flag for type of dropped RR intervals

%get rid of bad or missing HR data

if ~exist('dflag','var'),dflag=4;end
if ~exist('hrt','var'),hrt=[];end
if ~exist('hr','var'),hr=[];end

n=length(qt);
rrt=qt(2:n);
rr=1000*diff(qt);
drop=nicudrop(rr,hr,hrt,dflag);

qb=NaN*ones(n,1);
good=false(n,1);
g=find(drop==0);
ng=length(g);
if ng==0,return,end
good(g)=1;
good(g+1)=1;
g1=g(1);
urr=rr(g1);
qb(g1)=1;
qb(g1+1)=2;
nb=2;
for i=2:ng    
    g1=g(i-1)+1;
    g2=g(i);
    urr=(rr(g2)+rr(g1))/2;
    if g2>g1        
        dq=1000*(qt(g2)-qt(g1));
        db=1+round(dq/urr);
        db=max(db,2);
    else
        db=1;
    end
    nb=nb+db;
    qb(1+g2)=nb;
    if db>1
        qb(g2)=nb-1;
    end
end
bgood=~isnan(qb);
qb(~bgood)=interp1(qt(bgood),qb(bgood),qt(~bgood));

end

function drop=nicudrop(rr,hr,hrt,dflag)

if ~exist('dflag','var'),dflag=4;end
if ~exist('hr','var'),hr=[];end
if ~exist('hrt','var')
    urr=hr;
    hrt=[];
end

%Find expected RR interval for each beat
if ~isempty(hrt)
    rrt=cumsum(rr)/1000;
    qhr=interp1(hrt,hr,rrt);
    urr=60000./qhr;
end

nrr=length(rr);
if ~exist('urr','var'),urr=[];end

drop=zeros(nrr,1);

%Find good RR intervals

rrmax=2000;
rrmin=200;
j=rr<rrmin|rr>rrmax;
drop(j)=1;

if length(urr)==nrr
    rrmax=1.9*urr;
    rrmin=.6*urr;
    j=drop==0&(rr<rrmin|rr>rrmax);
    if dflag>1
        drop(j)=2;
    end    
end

dmin=75;
D=diff(rr);
d1=[inf;D];
d2=[D;inf];
ad1=abs(d1);
ad2=abs(d2);
j=drop==0&min(ad1,ad2)>dmin;
if dflag>2
    drop(j)=3;
end
dmax=200;
rrmax1=600;
j=drop==0&rr>rrmax1&max(ad1,ad2)>dmax;
if dflag>3
    drop(j)=4;
end

end

