function name=datanames(file,group,filter)
%function name=datanames(file,group,filter)
%
%file       hdf5 file
%group      group to find datasets
%filter     datasets to find
%
%name       name of datasets

if ~exist('group','var'),group='/';end
if ~exist('filter','var'),filter='';end
info=[];

if ~isempty(group)
    try
        info=h5info(file,group);    
    end
else
    try
        info=h5info(file);    
    end
end
name=cell(0,1);
if isempty(info),return,end
if ~isfield(info,'Datasets'),return,end
Datasets=info.Datasets;
if isfield(Datasets,'Name')
    n=0;
    for i=1:length(Datasets)
        Name=Datasets(i).Name;
        if isempty(Name),continue,end
        Name=[group,'/',Name];        
        if ~isempty(filter)
            j=findstr(filter,Name);
            if isempty(j),continue,end
            Name(j(1):end)=[];
        end
        n=n+1;
        name{n,1}=Name;
    end    
end

if ~isfield(info,'Groups'),return,end
if ~isfield(info.Groups,'Name'),return,end
ng=length(info.Groups);
for i=1:ng
    name1=datanames(file,info.Groups(i).Name,filter);    
    name=[name;name1];    
end
