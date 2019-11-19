function [qb,good,rr,rrt,drop]=qrsgood(qt,hr,hrt,dflag)
%function [qb,good,rr,rrt,drop]=qrsgood(qt,hr,hrt,dflag)
%
%qt         time of detected beats in seconds
%hr         HR from monitor
%hrt        HR timestamps in seconds
%dflag      flag for RR intervals to drop
%
%qb         beat number of good heartbeats
%good       heartbeats associated with good RR intervals
%rr         estimated RR intervals
%rrt        time in seconds for estimated RR intervals
%drop       flag for type of dropped RR intervals

%get rid of bad or missing HR data

if ~exist('dflag','var'),dflag=[];end
if ~exist('hrt','var'),hrt=[];end
if ~exist('hr','var'),hr=[];end

n=length(qt);
rrt=qt(2:n);
rr=1000*diff(qt);
drop=nicudrop(rr,rrt,hr,hrt,dflag);

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
%nb=2;
for i=2:ng    
    g1=g(i-1);
    g2=g(i);
    qb(1+g2)=qb(1+g1)+1;    
    if g2==g1+1,continue,end
    urr=(rr(g2)+rr(g1))/2;        
    dq=1000*(qt(g2+1)-qt(g1+1));
    db=round(dq/urr);
    db=max(db,2);
    qb(1+g2)=qb(1+g1)+db;
    qb(g2)=qb(1+g2)-1;
end
bgood=~isnan(qb);
qb(~bgood)=interp1(qt(bgood),qb(bgood),qt(~bgood));

end

function drop=nicudrop(rr,rrt,hr,hrt,dflag)

if ~exist('dflag','var'),dflag=[];end
if ~exist('rrt','var'),rrt=[];end
if ~exist('hr','var'),hr=[];end
if ~exist('hrt','var')
    urr=hr;
    hrt=[];
end

if isempty(rrt)
    rrt=cumsum(rr)/1000;
end

%Find expected RR interval for each beat
if ~isempty(hrt)
    qhr=interp1(hrt,hr,rrt);
    urr=60000./qhr;
end

nrr=length(rr);
if ~exist('urr','var'),urr=[];end
if isempty(dflag)
    if length(urr)==nrr
        dflag=2;
    else
        dflag=1;
    end
end
        
drop=zeros(nrr,1);

%Find good RR intervals
rrmax=2000;
rrmin=200;
j=rr<rrmin|rr>rrmax;

if dflag>0
    drop(j)=1;
end

if length(urr)==nrr
%     rrmax=1.9*urr;
%     rrmin=.6*urr;
    rrmax=1.1*urr;
    rrmin=.9*urr;
    j=drop<1&(rr<rrmin|rr>rrmax);
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

