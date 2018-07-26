function [qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt,gain,fs)
%function [qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt,gain,fs)
%
% ecg ECG waveform
% ecgt timestamp for EKG
% gain gain for EKG (default 400)
% fs sampling freauency for interpolated signal (default=240Hz)
%
% qt times of detected heartbeats
% qb beat number of detected heartbeats
% qgood flag for good heartbeats
% x interpolated EKG signal
% xt timestamps for interpolated EKG signal

%Find time range
e1=round(fs*min(ecgt));
e2=round(fs*max(ecgt));
xt=(e1:e2)'/fs;

[x,xt,xna]=naninterp(double(ecg)/gain,ecgt,xt);
x = fillmissing(x,'nearest');

%QRS detection
[q,sign,en_thres]=qrs_detect2(x,0.2,0.6,fs);
q=q(:);
nq=length(q);
qt=xt(q);

%Find good hearbeats and RR intervals
[qb,qgood,rr,rrt,drop]=qrsgood(qt);

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

