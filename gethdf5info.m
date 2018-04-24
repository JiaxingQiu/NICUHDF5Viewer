function [Data,Time,Groups,info]=gethdf5info(hdf5file,group)
%function [Datasets,Name,Groups,info]=gethdf5info(hdf5file,group)

if ~exist('group','var'),group='/';end
Datasets=[];
Data=cell(0,1);
Time=cell(0,1);
Groups=cell(0,1);
info=[];

if ~isempty(group)
    try
        info=h5info(hdf5file,group);    
    end
else
    try
        info=h5info(hdf5file);    
    end
end

if isempty(info),return,end
if ~isfield(info,'Groups'),return,end
nd=length(info.Groups);
Groups=cell(nd,1);
Data=cell(nd,1);
Time=cell(nd,1);
for i=1:nd
    if isfield(info.Groups(i),'Name')
        Data{i}=horzcat(info.Groups(i).Name,'/data');   
        Time{i}=horzcat(info.Groups(i).Name,'/time');
        Groups{i} = info.Groups(i).Name;
    end
end
