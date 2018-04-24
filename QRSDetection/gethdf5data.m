function [data,Name,info,Groups,g]=gethdf5data(hdf5file,Groups,Name,sigstart,sigsamples)
%function [data,Name]=gethdf5data(hdf5file,Groups,Name)
%
%hdf5file - HDF5 file with wavleform and vital sign data
%Groups - name of groups to retrieve
%         0 => both vital signs and waveforms (default)
%         1 => just vital signs
%         2 => just waveforms
%
%Name - name of datasets to retrieve ... empty => all (default);
%
%data - structure with data and timestamps
%info - information about entire HDF5 file
%g - group number for each dataset

data=[];
info=[];
if ~exist('Groups','var'),Groups=0;end
if ~exist('Name','var'),Name=cell(0,1);end

%Determine which data groups are being requested
if isnumeric(Groups)
    switch Groups
        case 0
            Groups={'/VitalSigns','/Waveforms'};        
        case 1
            Groups={'/VitalSigns'};
        case 2
            Groups={'/Waveforms'};
        otherwise
            Groups={''};
    end
end                     
if ~iscell(Groups)
    if ischar(Groups)
        Groups={Groups};
    end
end
ng=length(Groups);

%All data for requested group flag
alldata=isempty(Name);
if ischar(Name)
    Name={Name};
end

%Read in all dataset info
[allName,allGroups,allDatasets,info]=gethdf5info(hdf5file);

%Find time stamp datasets
tsub=strmatch('/Events/Times',allGroups);
tname=allName(tsub);
tGroups=allGroups(tsub);
times=allDatasets(tsub);

%Find requested datasets
n=length(allName);
g=NaN*ones(n,1);
for i=1:ng
    g(strmatch(Groups{i},allGroups,'exact'))=i;
end

sub=g>0;
    
allName=allName(sub);
allGroups=allGroups(sub);
allDatasets=allDatasets(sub);
g=g(sub);

if alldata,Name=allName;end
n=length(Name);

%Read in signal data
for i=1:n
    data(i,:).name=Name{i};
    data(i).Groups='';    
    data(i).x=[];    
    data(i).t=[];            
    data(i).times=[];       
    if ~alldata
        j=strmatch(Name{i},allName,'exact');
        if length(j)~=1,continue,end
    else
        j=i;
    end
    data(i).Groups=allGroups{j};        
    data(i).Datasets=allDatasets(j);
    x=h5read(hdf5file,[allGroups{j},'/',Name{i}],[1,sigstart],[1,sigsamples]);    
    if isempty(data),continue,end
    x=x(:);
    data(i).x=x;
end

%Read in timestamps
nt=length(tname);
for i=1:nt
    j=strmatch(tname{i},Name,'exact');    
    if length(j)~=1,continue,end    
    data(j).times=times(i);  
    t=h5read(hdf5file,[tGroups{i},'/',tname{i}],[1,sigstart],[1,sigsamples]);    
    if isempty(t),continue,end
    t=double(t(:));
    data(j).t=t;
end
