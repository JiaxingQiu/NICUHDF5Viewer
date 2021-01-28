function [data,t,T]=geth5time(file,data,T)
%function [data,t,T]=geth5time(file,name,T)
%
%file       hdf5 file
%data       srtucture with name of datasets
%T          block period in milliseconds
%
%data       dataset structure with requested time stamps and attributes
%t          global time matrix in milliseconds
%           corrected/original in first/second column

if ~exist('T','var'),T=NaN;end

t=zeros(0,2);
n=length(data);
name=cell(n,1);
if n==0,return,end

for i=1:n    
    dataset=data(i).name;    
    name{i}=dataset;
    
    tgroup=[dataset,'/time'];
    tsize=[0 0];
    try
        tinfo=h5info(file,tgroup);
        tsize=tinfo.Dataspace.Size;
    end
%    data(i).tsize=tsize;
    t=[];
    try
        t=h5read(file,[dataset,'/time']);
    end
    t=double(t);
    if size(t,2)>size(t,1)
        t=t';
        t=t(:,1);
    end
    nt=length(t);   
    data(i).t=t;
    data(i).nt=nt;
    data(i).T=T;
    if isnan(T)
        try
            data(i).T=h5readatt(file,dataset,'Sample Period (ms)');
        end
    end
end
if isnan(T)
    T=double(cat(1,data.T));
    [T,~,ic]=unique(T);
    nT=length(T);
%     if nT>1
%         T=NaN;
%     end
    nn=zeros(nT,1);
    for i=1:nT
        nn(i)=sum(ic==i);
    end
%    disp([T nn])
    [~,j]=max(nn);
    T=T(j);
end

[data,t,T]=fixtime(data,T);

end

function [data,t,dt]=fixtime(data,dt)
%function [data,t,dt]=fixtime(data,dt)
%
% data      structure with time stamps for each signal
% dt        intended time between timestamps
%
% data      sequence added and correced time stamps signal
% t         time matrix with corrected/original in first/second column

%Find original time sequence

if ~exist('dt','var'),dt=NaN;end

[t,s,seq]=timeseq(data);
t0=t;

if isnan(dt)
    dt=median(diff(t));
end

n=length(data);

%Fix jitter of global timestamps to make increasing and multiple of dt

t=fixjitter(t0,dt);

%Put original times in second column
t(:,2)=t0;

%Replae timestamps with sequence number in data structure
for i=1:n
    j=seq(s==i);
%Remove timestamps and find blocks of consecutive data in index
    data(i).t=[];
    j1=min(j);
    j2=max(j);    
    k=find(diff(j)>1);
    if ~isempty(k)       
        j2=[j(k);j2];
        j1=[j1;j(k+1)];
    end
    index=[j1 j2-j1+1];
    data(i).index=index;
    data(i).seq=ind;        
%Put corrected timestamps back into data structure    
%    data(i).t=t(ind,1);

end

end

function [t,s,seq,tnum,T,Tnum,D]=timeseq(data)
%function [t,s,seq,tnum,T,Tnum,D]=timeseq(data)
%
% data = structure with time stamps for each signal
%
% t         all unique timestamps
% tnum      unique timestamps duplicate numbers 
% s         signal number for all timestamps
% seq       sequence number for all timestamps
% T         all timestamps
% Tnum      all timestamps duplicate numbers 

t=[];
tnum=[];
T=[];
Tnum=[];
s=[];
seq=[];
D=[];
n=length(data);
if n==0,return,end
for i=1:n
    tt=double(data(i).t);    
    nt=length(tt);
    if nt==0,continue,end
    tn=ones(nt,1);
    dup=[0;diff(tt)==0];
    j=find(dup);
    for k=1:length(j)
        jj=j(k);
        tn(jj)=tn(jj-1)+1;
    end
    T=[T;tt];
    s=[s;i*ones(nt,1)];
    Tnum=[Tnum;tn];
end

maxnum=max(Tnum);
D=10.^ceil(log10(maxnum));

%Find all unique times
[Dt,~,seq]=unique(D*T+Tnum);
t=floor(Dt/D);
tnum=Dt-D*t;

end

function [t,td,d,st,t0]=fixjitter(t,dt)
%function [t,td,d,st]=fixjitter(t,dt)
%
%t      original time stamps in seconds
%dt     target time between samples (default 2 seconds)
%
%t      corrected times
%td     amount corrected
%d      cumulative jitter
%st     ideal times without jitter
%t0     anchor time point

if ~exist('dt','var'),dt=1;end

%Find ideal samples
t0=t(1);
nt=length(t);
st=t0+(0:(nt-1))'*dt;

%Find cumulative minimum drift of actual vs ideal
ds=t-st;
d=cummin(ds,'reverse');

%Correction
td=d-ds;
t=t+td;

if dt==1,return,end

%Find original time point with smallest correction as anchor

j0=find(abs(td)==min(abs(td)),1);
t0=t(j0);

%Force times to be multiple of dt
if dt>1      
    t=t0+dt*ceil((t-t0)/dt);
end

end