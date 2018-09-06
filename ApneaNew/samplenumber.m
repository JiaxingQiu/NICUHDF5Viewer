function [sample,start,st,xt,d,g]=samplenumber(t,fs,block,start,gap)
%function [sample,st,fs]=samplenumber(t,block,fs,gap)
%

if ~exist('fs','var'),fs=1;end
if ~exist('start','var'),start=[];end
if ~exist('block','var'),block=fs;end
dt=block/fs;
if ~exist('gap','var'),gap=floor(2*dt)+1;end

nt=length(t);
N=nt*block;
st=NaN*ones(nt,1);
xt=NaN*ones(N,1);
sample=NaN*ones(N,1);

if N==0,return,end

[g1,g2,g]=findgaps(t,gap);
ng=length(g1);

%Set start time to first point
if isempty(start)
    start=t(1)-dt;
end

%Find time stamps for blocks and original signal
d=dt*ones(ng,1);

for i=1:ng
%Indices of blocks
    j1=g1(i);
    j2=g2(i);
    j=(j1:j2)';    
    nn=length(j);    
%Indices of full signal     
    k1=(j1-1)*block+1;
    k2=j2*block;
    k=(k1:k2)';
    NN=length(k);    
%Find initial and end time points segment
    t1=t(j1)-dt;
    if i>1
        nd=round((t1-t2)/dd);
        t1=t2+(nd-1)*dd;
    end
    t2=t(j2);
%Duration of segment    
    tt=t2-t1;
%Actual time difference between samples if too much drift   
    if abs(t2-t1-nn*d(i))>=gap
        d(i)=tt/nn;
    end
    dd=d(i);
    st(j)=t1+(1:nn)'*dd;
    xt(k)=t1+(1:NN)*dd/block;
    t2=st(j2);    
end

%Convert to sample numbers at specified frequency
if fs>1
    sample=round((xt-start)*fs);
else
    sample=xt-start;
end

end

function [g1,g2,g]=findgaps(t,gap)

if ~exist('gap','var'),gap=2;end

nt=length(t);
g1=1;
g2=nt;
g=ones(nt,1);    
%Find blocks of consecutive data
j=find(diff(t)>=gap);
if isempty(j),return,end
g1=[g1;(j+1)];
g2=[j;g2];
ng=length(g1);
if nargout<3,return,end
for i=1:ng
    g(g1(i):g2(i))=i;
end

end