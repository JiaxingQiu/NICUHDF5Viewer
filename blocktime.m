function [T,fs,block]=blocktime(x,t,dt,tmax)
%function [T,fs,block]=blocktime(x,t,dt,tmax)
%
%x - input signal
%t - time stamp for each block
%dt - time for each block
%tmax - gap to start new block of consecutive values
%
%T - time vector for each point
%fs - sampling frequency
%block - block size

% dt: Doug thinks GE has a default of 2 seconds and Philips is default 1 second

if ~exist('dt','var'),dt=1;end
if ~exist('tmax','var'),tmax=dt+1;end

n=length(x);
T=NaN*ones(n,1);
nt=length(t);
block=n/nt;
fs=block/dt;
if nt==0,return,end
t=double(t);
start=t(1);

%Find gaps in data
if nt>1
    b=find(diff(t)>tmax);
else
    b=[];
end

%Find blocks of consecutive data
b1=1;
b2=nt;
if ~isempty(b)
    b1=[1;(b+1)]; % block start (time index)
    b2=[b;nt];    % block end (time index)
end

%Find size and start/stop times of each block 
nb=length(b1);
bs=(b2-b1+1)*block; % number of samples in each block
t1=t(b1); % find the time stamps (in utc time, which correspond to the block start indices)
t2=t1+bs/fs; % find the time stamps (in utc time, which correspond to the block end indices)
stop=t2(nb);

%Put time stamps into consecutive values for each block
k1=0;
for i=1:nb
    nn=bs(i);
    k=k1+(1:nn)';
    T(k)=t1(i)+(1:nn)'/fs;
    k1=k1+nn;
end
