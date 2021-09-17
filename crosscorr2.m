function [c,lags,z,zt]=crosscorr2(vdata,vt,maxlag,dt)
%function [c,lags,z,zt]=crosscorr2(vdata,vt,maxlag,dt)
%
% vdata     input matrix of signals in 2 columns (NaN=missing)
% vt        time stamp in seconds
% maxlag    maximum lag to calculate (default 15)
% dt        time resolution to interpolate (default 2 sec)
%
% c         cross-correlation function of standardized signals
% lags      lags for cross-correlation
% z         standardized signals 
% zt        times for standardized signals

if ~exist('maxlag','var'),maxlag=15;end

z=[];
zt=[];
lags=(-maxlag:maxlag)';      
nlags=length(lags);
c=NaN*ones(nlags,1);

if isempty(vt),return,end

[n,m]=size(vdata);
if m<2,return,end

vdata=vdata(:,1:2);

np=sum(~isnan(vdata),1);
if min(np)<2,return,end

sx=nanstd(vdata);
if sum(sx>0)<2,return,end

if ~exist('dt','var'),dt=2;end

if dt~=1
    lags=dt*lags;    
end

%Downsample to specified time resolution

% xt=dt*ceil(vt/dt);
% [xt,ia]=unique(xt,'last');
% x=vdata(ia,:);

[x,xt]=newsample(vdata,vt,dt);

%Find minimum and maximum points
t1=xt(1);
t2=xt(end);
zt=(t1:dt:t2)';

nt=length(zt);
if nt==0,return,end

%Standardize signals using original mean and SD
%Fill in missing points with 0

z=NaN*ones(nt,2);

%Find common points
[~,jx,jz]=intersect(xt,zt);
z(jz,:)=x(jx,:);
u=ones(nt,1)*nanmean(x,1);
s=ones(nt,1)*nanstd(x,0,1);
z=(z-u)./s;
z(isnan(z))=0;

try
    c=xcorr(z(:,1),z(:,2),maxlag)/nt;    
end
