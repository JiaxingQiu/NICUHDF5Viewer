function [y,ynum,ymax,ymin,yt,nu,nmax]=downsamplestats(x,fs,ns,dx,skip)
%
% x     input raw signal
% fs    sampling frequency
% ns    number of samples per second
% dx    tolerance for consitent "good" data
% skip  number of dsta points to skip for next window
%
% y     most frequent value in window
% ymax  maximum value in window
% ymin  minimum value in window
% ynum  number of good points in window
% yt    time stamp
% nu    number of unique values in window
% nmax  number of most frequent value

if ~exist('fs','var'),fs=200;end
if ~exist('ns','var'),ns=1;end
if ~exist('dx','var'),dx=.5;end
if ~exist('skip','var'),skip=fs/ns;end

N=length(x);

%Window indices
j2=(skip:skip:N)';
j1=j2-fs+1;
j1(j1<1)=1;
yt=j2/fs;
nt=length(yt);
y=NaN*ones(nt,1);
ynum=NaN*ones(nt,1);
ymax=NaN*ones(nt,1);
ymin=NaN*ones(nt,1);
nu=NaN*ones(nt,1);
nmax=NaN*ones(nt,1);
for i=1:nt
    j=(j1(i):j2(i))';
    xx=x(j);
    uxx=unique(xx);
    m=length(uxx);
    nn=zeros(m,1);
    for k=1:m
        nn(k)=sum(xx==uxx(k));
    end
    [nmax(i),k]=max(nn);
    y(i)=uxx(k);
    ynum(i)=sum(abs(xx-y(i))<=dx);
    nu(i)=m;    
    ymin(i)=uxx(1);
    ymax(i)=uxx(end);
end
    