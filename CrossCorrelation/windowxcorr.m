function [cmax,c,ct,cn,lag,x,xt]=windowxcorr(id,start,stop,dt,vitaldir)
%function [cmax,c,ct,cn,lag,x,xt]=windowxcorr(id,start,stop,dt,vitaldir)
%
% Input
%
% id - patient id
% start - start days of age
% stop - stop days of age
% dt - window size (default 10 minutes)
%
% Output
%
% cmax - max xcorr for each time window
% c - matrix with correlation for each lag and time window
% ct - age for end of each time window
% cn - number of vital signs in each window
% lag - lags for each crosscorr calculation
% x - raw HR and SPO2 vital signs
% xt - time stamps for raw vital signs

% Set default values

if ~exist('vitaldir','var')
    vitaldir='E:\ByWeek\';
end
if ~exist('dt','var'),dt=1/144;end
if ~exist('stop','var'),stop=Inf;end
if ~exist('start','var'),start=0;end
maxlag=30;
lag=(-maxlag:maxlag)';      
nlag=length(lag);

%Get HR and SPO2
[x,xt]=getvitals(id,{'HR','SPO2-%'},start,stop,vitaldir);
good=sum(x>0,2)==2;
x=x(good,:);
xt=xt(good);
w=[-dt 0];
ct=unique(ceil(xt/dt))*dt;
nt=length(ct);
[j1,j2]=windowtimes(ct,w,xt);
c=NaN*ones(nt,nlag);
cmax=NaN*ones(nt,1);
cn=zeros(nt,1);
for i=1:nt
    j=(j1(i):j2(i))';    
    if isempty(j),continue,end    
    cn(i)=length(j);
    tt=86400*xt(j);
    [cmax(i),cc]=crosscorr2(x(j,1:2),tt,maxlag,1);
    c(i,:)=cc';
end
