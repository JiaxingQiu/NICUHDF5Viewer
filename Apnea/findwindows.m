function [w1,w2]=findwindows(wt,w,t)
%function [w1,w2]=findwindows(wt,w,t)
%
%wt - time 0 for each window
%w - window start and ending offsets
%t - time stamp of data to be windowed
%
% Window i : wt(i)+w(1)<t<=wt(i)+w(2)
%
%w1 - starting indexes for window
%w2 - ending indexes for window

if ~exist('t','var'),t=wt;end

if length(w)==1
    w=[-w w];
end
    
nw=length(wt);
nt=length(t);
w1=NaN*ones(nw,1);
w2=NaN*ones(nw,1);
j1=1;
for i=1:nw
    t1=wt(i)+w(1);    
    if t1>=t(nt),break,end
    t2=wt(i)+w(2);        
    if t2<t(j1),continue,end
    for j=j1:nt
        j1=j;
        if t(j)>t1,break,end
    end    
    if t(j1)>t2,continue,end    
    j2=j1;
    for j=(j1+1):nt
        if t(j)>t2,break,end
        j2=j;
    end
    w1(i)=j1;
    w2(i)=j2;
end
