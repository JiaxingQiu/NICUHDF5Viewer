function [data,Name,info,Groups,g]=gethdf5data(hdf5file,Groups,Name)
%function [data,Name]=gethdf5data(hdf5file,Groups,Name)
% Example: [data,Name,info,Groups,g]=gethdf5data('X:\Amanda\TestInputFiles\UVA\BedmasterUnity\NICU_A1-1444723999_2015101.hdf5',2,{'/Waveforms/II';'/Waveforms/III'});
% Example: [data,Name,info,Groups,g]=gethdf5data('X:\Amanda\TestInputFiles\UVA\BedmasterUnity\NICU_A1-1444723999_2015101.hdf5',1);
% Example: [data,Name,info,Groups,g]=gethdf5data('X:\Amanda\TestInputFiles\UVA\BedmasterUnity\NICU_A1-1444723999_2015101.hdf5',0);
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
nn=size(Name,1);

%All data for requested group flag
alldata=isempty(Name);
if ischar(Name)
    Name={Name};
end

%Read in all dataset info
% [allName,allGroups,allDatasets,info]=gethdf5info(hdf5file);
for gr=1:length(Groups)
    if gr==1
        [allData,allTimes,allGroups,info]=gethdf5info(hdf5file,Groups{1});
    else
        [allData1,allTimes1,allGroups1,info1]=gethdf5info(hdf5file,Groups{gr});
        allData = vertcat(allData,allData1);
        allTimes = vertcat(allTimes,allTimes1);
        allGroups = vertcat(allGroups,allGroups1);
        info = vertcat(info,info1);
    end
end


%Find requested datasets
n=length(allData);
g=NaN*ones(n,1);
for i=1:nn
    g(strmatch(Name{i},allGroups,'exact'))=i;
end

sub=g>0;
    
if ~alldata
    allData=allData(sub);
    allGroups=allGroups(sub);
    allTimes=allTimes(sub);
    g=g(sub);
end

if alldata,Name=allGroups;end
n=length(Name);

%Read in signal data
for i=1:n
    data(i).name=Name{i};
    data(i).x=[];    
    data(i).t=[];                 
    if ~alldata
        j=strmatch(Name{i},allGroups,'exact');
        if length(j)~=1,continue,end
    else
        j=i;
    end

    x=double(h5read(hdf5file,allData{j}))';    % Amanda changed the orientation of the array so that when blocktime looks for gaps and needs to concatenate vertically, there isn't a problem
    x(x==-32768) = NaN;     % Add NaNs where data is missing
    scale = double(h5readatt(hdf5file,allData{j},'Scale'));
    layoutversion = h5readatt(hdf5file,'/','Layout Version');
    % For layout version 3, scale is simply a multiplicative factor for the original value. To get the real value, you divide by scale. For layout version 4.0, a real value of 1.2 is stored as 12 with a scale of 1, where scale is stored as the power of 10, so to convert from 12 back to 1.2, you need to divide by 10^scale. Later in this code, when we are actually plotting the data, we divide by scale
    if str2double(layoutversion{1}(1)) ~= 3 
        scale = 10^scale;
    end
    x = x/scale;
    t=double(h5read(hdf5file,allTimes{j}))';    % Amanda changed the orientation of the array so that when blocktime looks for gaps and needs to concatenate vertically, there isn't a problem
    if isempty(data),continue,end
    data(j).x=x;
    data(j).t=t;
end