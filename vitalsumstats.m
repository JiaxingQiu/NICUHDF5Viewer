function [x,xt,xname]=vitalsumstats(vdata,vt,vname,dw,w,cv,dt,numLags)
%function [x,xt,xname]=vitalsumstats(vdata,vt,vname,dw,w,cv,dt,numLags)
% vdata - raw 2-second vital sign vdata
% vt - times of vital signs
% vname - vital sign names
% dw - calculation frequency in seconds
%      (default - every 5 minutes)
% w  - window for calculations in seconds
%      (default - last 10 minutes)
% cv - pairs of vital signs to do cross-correlation (default all)
%
% x - calculated statistics
% xt - times of calculations
% xname - feature names

if ~exist('dt','var'),dt=2;end
if ~exist('numLags','var'),numLags=15;end
if ~exist('vt','var'),vt=[];end
if ~exist('dw','var'),dw=300;end
if ~exist('w','var'),w=[-600 0];end
if ~exist('vname','var')
    vname={'HR','RESP','SPO2-%','SPO2-R'}';
end

x=[];
xt=[];
xname=cell(0,1);

nv=length(vname);
if isstr(vdata)
    m=matfile(vdata);
    vname0=m.vname;
    vt=m.vt;   
    nt=length(vt);
    sub=(1:nt)';    
    if length(vt)==2
        vt1=vt(1);
        vt2=vt(2);
        sub=find(vt>=vt1&vt<=v2);
        vt=vt(sub);
        nt=length(vt);        
    end
    if isempty(sub),return,end
    vdata=NaN*ones(nt,nv);
    for i=1:nv
        c=strmatch(vname{i},vname0,'exact');
        if isempty(c),continue,end
        vdata(:,c)=m.vdata(sub,i);
    end    
end

xname=cell(5*nv,1);
for i=1:nv
    xname{i}=['Num ',vname{i}];
    xname{nv+i}=['Mean ',vname{i}];
    xname{2*nv+i}=['SD ',vname{i}];
    xname{3*nv+i}=['Skewness ',vname{i}];    
    xname{4*nv+i}=['Kurtosis ',vname{i}];        
end

%Correlation Parameters

nmin=200;
if ~exist('cv','var')
    nc=nv*(nv-1)/2;
    cv=zeros(nc,2);
    k=0;
    for i=1:nv
        for j=(i+1):nv
            k=k+1;
            cv(k,1)=i;
            cv(k,2)=j;
        end
    end
end
nc=size(cv,1);
clab=cell(nc,1);
nx=length(xname);
for i=1:nc
    j=cv(i,1);
    k=cv(i,2);
    clab{i}=['XC ',vname{j},' ',vname{k}];    
    xname{nx+1}=['Max ',clab{i}];
    xname{nx+2}=['Lag Max ',clab{i}];
    xname{nx+3}=['Min ',clab{i}];
    xname{nx+4}=['Lag Min ',clab{i}];
    nx=nx+4;
end
nx=length(xname);

if size(vdata,2)<nv,return,end

tmin=min(vt);
tmax=max(vt);

wmin=ceil(tmin/dw);
wmax=ceil(tmax/dw);
xt=dw*(wmin:wmax)';
%[t1,t2]=windowtimes(xt,w,vt);
[t1,t2]=findwindows(xt,w,vt);
nw=t2-t1+1;
j=nw>0;
xt=xt(j);
t1=t1(j);
t2=t2(j);
nv=length(vname);
nt=length(xt);

u=NaN*ones(nt,nv);
s=NaN*ones(nt,nv);
skew=NaN*ones(nt,nv);
kurt=NaN*ones(nt,nv);
c=NaN*ones(nt,4*nc);
n=zeros(nt,nv);
%disp(nt)
for i=1:nt
    k=(t1(i):t2(i))';
    if isempty(k),continue,end
    v=double(vdata(k,:));
    tt=double(vt(k));    
    for j=1:nv
        xx=v(:,j);
%        vv=find(xx>0);
        vv=find(~isnan(xx));        
        if isempty(vv),continue,end
        xx=xx(vv);
        n(i,j)=length(xx);
        u(i,j)=mean(xx);
        s(i,j)=std(xx);
        skew(i,j)=skewness(xx);
        kurt(i,j)=kurtosis(xx);
    end
%    v(v<=0)=NaN;
    for j=1:nc
        jj=cv(j,1);
        kk=cv(j,2);        
        j0=4*(j-1);
        [xcf,lags]=crosscorr2(v(:,[jj kk]),tt,numLags,dt);
%        [xcf,lags]=xcorrstand(v(:,[jj kk]),tt,numLags,dt);        
        if sum(isnan(xcf))>0,continue,end
        [z,d]=max(xcf);
        c(i,j0+1)=z;        
        c(i,j0+2)=lags(d);
        [z,d]=min(xcf);
        c(i,j0+3)=z;
        c(i,j0+4)=lags(d);
    end    
end
x=[n u s skew kurt c];
nx=length(xname);



    
