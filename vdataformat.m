function [data,t,vname]=vdataformat(vdata,vformat)
%function [data,t,vname]=vdataformat(vdata,vformat)
%
%vdata      matrix/structure with vital sign values
%vformat    format of output 
%           0=> matrix and time stamps (default)
%           1=> long two-column matrix with vital sign number, and value
%
%data       vital sign values (matrix format)
%           vital sign number / vlaue pairs (long format)
%t          time stamps for data
%vname      vital sign names for matrix columns or vital sign numbers

if ~exist('vformat','var'),vformat=0;end

%Put all data into long vectors 
nv=length(vdata);
vname=cell(nv,1);

x=[];
v=[];
xt=[];
for i=1:nv
    vname{i}=vdata(i).name;
    xx=vdata(i).x;
    n=length(xx);    
    if n==0,continue,end
    tt=vdata(i).t;
    if length(tt)~=n,continue,end
    v=[v;i*ones(n,1)];
    x=[x;xx];    
    xt=[xt;tt];
end

%Long matrix output
if vformat>0
    data=[v x];
    t=xt;
    return
end
[t,~,r]=unique(xt);
nt=length(t);
data=NaN*ones(nt,nv);
for i=1:nv
    j=v==i;
    data(r(j),i)=x(j);
end