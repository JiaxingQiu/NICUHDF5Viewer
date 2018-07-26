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
