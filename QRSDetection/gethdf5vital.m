function [vdata,vname,vt,info]=gethdf5vital(hdf5file,sigstart,sigsamples,vname,vformat)
%function [vdata,vname,vt,info]=gethdf5vital(hdf5file,vname)
%
%hdf5file - HDF5 file with vital sign data
%vname - name of vital signs to retrieve ... 0 or empty => all (default);
%vformat - format of output 
%          0=> matrix and time stamps (default)
%          1=> long matrix with vital sign number, and value
%          2=> structure 
%
%vdata - matrix/structure with vital sign values
%vname - vital sign names for columns of the matrix
%vt - time stamps for row of the matrix for vformat=0
%info - information about entire HDF5 file

vdata=[];
vt=[];
info=[];
if ~exist('vname','var'),vname=cell(0,1);end
if ~exist('vformat','var'),vformat=0;end

allvital=isempty(vname);
[data,Name,info]=gethdf5data(hdf5file,'/Vital Signs',vname,sigstart,sigsamples);
if allvital
    vname=Name;
end
vdata=data;
%Stucture output
if vformat==1
    vt=unique(cat(1,vdata.t));
    return
end
nv=length(vdata);
if nv==0,return,end

%Put all data into long vectors 
t=[];
x=[];
v=[];
for i=1:nv
    n=length(vdata(i).t);
    if n==0,continue,end
    x=[x;vdata(i).x];    
    t=[t;vdata(i).t];
    v=[v;i*ones(n,1)];
end
%Long matrix output
if vformat==2
    vdata=[v x];
    vt=t;
    return
end
%Matrix output
[vt,~,r]=unique(t);
nt=length(vt);
vdata=NaN*ones(nt,nv);
for i=1:nv
    j=v==i;
    vdata(r(j),i)=x(j);
end
    