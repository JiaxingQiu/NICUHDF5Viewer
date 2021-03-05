function [c,lags,z1,z2,zt]=xcorrstand(x,t,maxlag,dt)
%function [c,lags,z1,z2,zt]=xcorrstand(x,t,maxlag,dt)
%
% x         input matrix of signals in 2 columns (NaN=missing)
% t         time stamp in seconds
% maxlag    maximum lag to calculate (default 15)
% dt        time resolution to interpolate (default 2 sec)
%
% c         cross-correlation function of standardized signals
% lags      lags for cross-correlation
% z1        standardized signal 1 
% z2        standardized signal 2 
% zt        times for standardized signals

if ~exist('dt','var'),dt=2;end
if ~exist('maxlag','var'),maxlag=15;end

z1=[];
z2=[];
zt=[];
lags=(-maxlag:maxlag)';      
nlags=length(lags);
c=NaN*ones(nlags,1);
[n,m]=size(x);

if m<2,return,end

%Ensure time stamps are increasing
if length(t)>1
    [t,j]=sort(t);
    x=x(j,:);    
end       

%Find minimum and maximum points
t1=ceil(min(t)/dt);
t2=floor(max(t)/dt);
zt=(t1:t2)';
if dt~=1
    zt=dt*zt;
end

nt=length(zt);
if nt==0,return,end

%Standardize signals using original mean and SD
%Fill in missing points with 0
z=zeros(nt,2);
for i=1:2
    good=~isnan(x(:,i));
    xx=x(good,i);
    u=mean(xx);
    s=std(xx);
    xx=(xx-u)/s;
    nn=length(good);    
    xt=t(good);
%Find common points
    if isinteger(median(diff(xt)))
        [~,jx,jz]=intersect(xt,zt);
        z(jz,i)=xx(jx);
    else
        [~, closestIndex] = min(abs(xt - zt'));
        z(:,i) = xx(closestIndex);
    end
end
z1=z(:,1);
z2=z(:,2);
try
    c=xcorr(z1,z2,maxlag)/nt;
end

if dt~=1
    lags=dt*lags;    
end



