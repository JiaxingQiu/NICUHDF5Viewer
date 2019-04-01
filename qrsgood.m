function [qb,good,rr,rrt,drop]=qrsgood(qt,dflag)
%function [good,rr,rrt,drop]=qrsgood(qt,hr,hrt,dflag)
%
%qt         time of detected beats in seconds
%dflag      flag for RR intervals to drop
%
%qb         beat number of good heartbeats
%good       heartbeats associated with good RR intervals
%rr         estimated RR intervals
%rrt        time in seconds for estimated RR intervals
%drop       flag for type of dropped RR intervals

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

