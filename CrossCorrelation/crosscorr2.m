function [cmax,c,lag,z,zt]=crosscorr2(x,t,maxlag,dt)
%function [c,lag,v,z,zt]=crosscorr2(x,t,maxlag,dt)
%
% x = input matrix of with signals in 2 columns
% t = time stamp in seconds
% maxlag = maximum lag to calculate
% dt = time resolution to interpolate (default 1-sec)
%
% cmax = max cross-correlation
% c = cross-correlation
% lag = lags
% z = standardized signals
% zt = standardized times

if ~exist('dt','var'),dt=1;end
if ~exist('maxlag','var'),maxlag=1;end

if dt~=1
    maxlag=ceil(maxlag/dt);
end
lag=(-maxlag:maxlag)';      
nlag=length(lag);
cmax=NaN;
c=NaN*ones(nlag,1);
[n,m]=size(x);
if m<2,return,end
%Make sure timestamps are sorted
[t,j]=sort(t);
x=x(j,:);
t1=dt*(ceil(min(t)/dt));
t2=dt*(floor(max(t)/dt));
zt=(t1:dt:t2)';
nt=length(zt);

if nt==0,return,end
x=x(:,1:2);

%normalize correlation to be unbiased
nz=nt-abs(lag);
if dt~=1
    lag=dt*lag;
end

z=NaN*ones(nt,2);
for i=1:2
    y=x(:,i);
    good=~isnan(y);
    yy=y(good);        
    if length(yy)<maxlag,continue,end
%times of measured points    
    tg=t(good);   
    u=mean(yy);
    s=std(yy);        
    zz=interp1q(tg,yy,zt);        
    zz=zz-u;
    if s>0
        zz=zz/s;
    end
%Find distance of interpolated point to measured point    
    d=zeros(nt,1);
    for j=1:nt
        d(j)=min(abs(zt(j)-tg));       
    end
%set missing points to zero    
    zz(d>dt)=0;
    zz(isnan(zz))=0;    
    z(:,i)=zz;
end

if max(nz)<0,return,end
c=xcorr(z(:,1),z(:,2),maxlag)./nz;
cmax=max(c);


