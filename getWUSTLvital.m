function [vdata,vlabel,vtout,info]=getWUSTLvital(values,vtin,vlabel,vformat)
%function [vdata,vlabel,vt,info]=getWUSTLvital(hdf5file,vlabel)
%
%hdf5file - HDF5 file with vital sign data
%vlabel - name of vital signs to retrieve ... 0 or empty => all (default);
%vformat - format of output 
%          0=> matrix and time stamps (default)
%          1=> long matrix with vital sign number, and value
%          2=> structure 
%
%vdata - matrix/structure with vital sign values
%vlabel - vital sign names for columns of the matrix
%vt - time stamps for row of the matrix for vformat=0
%info - information about entire HDF5 file

info=[];
if ~exist('vlabel','var'),vlabel=cell(0,1);end
if ~exist('vformat','var'),vformat=0;end

vdata=values;
%Stucture output
if vformat==1
    vt=unique(cat(1,vtin));
    return
end
nv=size(vdata,2);
if nv==0,return,end

%Put all data into long vectors 
t=[];
x=[];
v=[];

timediffs = diff(datetime(vtin,'ConvertFrom','datenum'));
jumps = find(timediffs>seconds(2)); % the index where a time jump takes place that is greater than 2 seconds
startindex = 1;
consecutivetimearray = [];
consecutivedataarray = [];
for j=1:length(jumps)
    roundedstarttime = datenum_round_off(vtin(startindex),'second');
    roundedendtime = datenum_round_off(vtin(jumps(j)),'second');
    consecutivetimearray = vertcat(consecutivetimearray,(roundedstarttime:datenum(seconds(1)):roundedendtime)');
    consecutivedataarray = vertcat(consecutivedataarray,vdata(startindex:jumps(j),:));
    minlength = min(size(consecutivetimearray,1),size(consecutivedataarray,1));
    consecutivetimearray = consecutivetimearray(1:minlength,:);
    consecutivedataarray = consecutivedataarray(1:minlength,:);
    startindex = jumps(j)+1;
end
    

roundedtime = datenum_round_off(vtin,'second');

mastertime = (roundedtime(1):datenum(seconds(1)):roundedtime(end))';
M = ismember(datevec(mastertime),datevec(roundedtime),'rows');

for i=1:nv
    n=length(vdata(:,i));
    if n==0,continue,end
        
    vtemp = ones(length(mastertime),1)*nan;
    vtemp(M) = vdata(:,i);
    vtemp(vtemp==8388607) = nan;
    n = length(vtemp);
    x = [x;vtemp];    
    t = [t;mastertime];
    v = [v;i*ones(n,1)];
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
    vtout(r(j),i)=vt(j);
end

