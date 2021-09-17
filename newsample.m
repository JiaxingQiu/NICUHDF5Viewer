function [xdata,xt]=newsample(vdata,vt,dt)
%function [xdata,xt]=newsample(vdata,vt,dt)
%
% vdata     raw vital sign data (NaN=missing)
% vt        times of vital signs 
% dt        time resolution for new sample (default 2 sec)
%
% xdata     newly sampled vital sign data a
% xt        new time stamps 

if ~exist('dt','var'),dt=2;end

[n,m]=size(vdata);
xdata=vdata;
xt=vt;

%New sampling rate and in long format 
x=[];
t=[];
v=[];
for i=1:m    
    xx=vdata(:,i);
    good=~isnan(xx);
    xx=xx(good);
    nx=length(xx);    
    if nx==0,continue,end            
    tt=vt(good);
    tt=dt*ceil(tt/dt);
    [tt,ia]=unique(tt,'last');
    xx=xx(ia);        
    nx=length(xx);
    v=[v;i*ones(nx,1)];
    x=[x;xx];    
    t=[t;tt];
end

%Convert back to matrix format
[xt,~,r]=unique(t);
nt=length(xt);
xdata=NaN*ones(nt,m);
for i=1:m
    j=v==i;
    xdata(r(j),i)=x(j);
end





