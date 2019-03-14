function [data,name,info]=getfiledata(info,name,alldata)
%function [data,info,name]=getdata(file,name)
%
%info       structure with file name and all dataset attributes/names
%           or just file name to retrieve data from
%name       name of datasets to retrieve (empty=default => all) 
%alldata    dataset structure with all data if previously retrieved
%
%data       dataset structure with requested data, time stamps and attributes
%name       name of datasets
%info       structure with time stamps and all dataset attributes/names

if ~exist('name','var'),name=cell(0,1);end
if ~exist('alldata','var'),alldata=[];end

if ischar(name),name={name};end
if length(name)==1
    onlyinfo=strcmp(name{1},'info');
end
data=[];
file='';
t=[];
newdata=isempty(alldata);

if isstruct(info)
    if isfield(info,'file')
        file=info.file;
    end
else
    file=info;
    info=[];
end

%Get information about file if new data
if newdata
    if isempty(info)
        info=getfileinfo(file);
    end
    if isfield(info,'alldata')
        alldata=info.alldata;
    end    
end

%Find all dataset names
n=length(alldata);
allname=cell(n,1);
if isfield(alldata,'name')
    for i=1:n
        allname{i}=alldata(i).name;
    end
end

%Find requested names
if isempty(name)
    name=allname;
    data=alldata;
else
    if n>0
        [name,index]=findindex(allname,name);
        data=alldata(index);
    end
end

ishdf5=endsWith(file,'.hdf5');
if ~ishdf5,return,end

%Read in requested data from HDF5 file if doesn't exist already
n=length(data);    
for i=1:n
    x=data(i).x;
%Convert to row vector if necessary    
    if ~isempty(x),continue,end    
    try
        x=h5read(file,[data(i).name,'/data']);         
    end
    xsize=size(x);
    if xsize(2)>xsize(1)
        x=x';
        x=x(:,1);
    end
    data(i).raw=true;
    data(i).x=x;
    nx=length(x);
    data(i).nx=nx;
end

end

function [name,index]=findindex(allname,name)
%function [index]=findindex(allname,name)
%
%allname    name of all datasets 
%name       name of datasets to retrieve (empty=default => all) 
%
%index      indices for requested names
%name       name of datasets 

if ~exist('name','var'),name=cell(0,1);end
if ischar(name),name={name};end

n=length(allname);
if isempty(name)
    index=(1:n)';
    return
end

allname=[allname fixedname(allname)];

%Find requested names
sub=zeros(n,1);
for i=1:length(name)
    j=strmatch(name{i},allname(:,1),'exact');
    if isempty(j)
        group=length(strfind(name{i},'/'))==1;
        if group
            j=strmatch(name{i},allname(:,1));
        end
    end
    if ~isempty(j)    
        sub(j)=1;
        continue
    end
    j=strmatch(name{i},allname(:,2),'exact');
    if ~isempty(j)
        sub(j)=2;
    end
end

index=find(sub>0);
n=length(index);
name=cell(n,1);
for i=1:n
    j=index(i);
    name{i}=allname{j,sub(j)};
end

end
