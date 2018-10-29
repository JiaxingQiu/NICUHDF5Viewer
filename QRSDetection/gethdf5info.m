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


% function [Name,Groups,Datasets,info]=gethdf5info(hdf5file,group)
% %function [Datasets,Name,Groups,info]=gethdf5info(hdf5file,group)
% 
% if ~exist('group','var'),group='/';end
% Datasets=[];
% Name=cell(0,1);
% Groups=cell(0,1);
% info=[];
% 
% if ~isempty(group)
%     try
%         info=h5info(hdf5file,group);    
%     end
% else
%     try
%         info=h5info(hdf5file);    
%     end
% end
% 
% if isempty(info),return,end
% if ~isfield(info,'Datasets'),return,end
% Datasets=info.Datasets;
% nd=length(Datasets);
% Groups=cell(nd,1);
% for i=1:nd        
%     Groups{i}=group;
% end
% Name=cell(nd,1);
% if isfield(Datasets,'Name')
%     for i=1:nd
%         Name{i}=Datasets(i).Name;
%     end    
% end
% %if nd>0,return,end
% if ~isfield(info,'Groups'),return,end
% if ~isfield(info.Groups,'Name'),return,end
% ng=length(info.Groups);
% for i=1:ng    
%     [Name1,Groups1,Datasets1]=gethdf5info(hdf5file,info.Groups(i).Name);
%     Name=[Name;Name1];    
%     Groups=[Groups;Groups1];
%     Datasets=[Datasets;Datasets1];
% end
