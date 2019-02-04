function [dataout,vt,varname] = loadsignal(hdf5file, signame)
% loadsignal pulls an individual signal from an hdf5 file. It returns a
% scaled version of the signal that has a time stamp compatible with the
% global timestamps
%
% hdf5file: a string with the full path of the file of interest
%
% signame can be any one of the following:
%    'Pulse'
%    'HR'
%    'SPO2_pct'
%    'Resp'
%    'ECGI'
%    'ECGII'
%    'ECGIII'

% Load all variable names in the file
varnames = datanames(hdf5file);

% Get the list of all possible variable strings that go with the desired signame
load('X:\Amanda\NICUHDF5Viewer\VariableNames','VariableNames')
varnamestruct = getfield(VariableNames,signame);

% Find out which of the variable names in the file matches with the desired signame list
dataindex = [];
for i = 1:length(varnamestruct)
    varname = varnamestruct(i).Name;
%     if sum(contains(varnames,varname))
    if sum(ismember(varnames,[varname '/data']))
        dataindex = ismember(varnames,[varname '/data']);
        VorW = varnamestruct(i).VorW;
        break
    end
end

% Extract the data (labeled as varname) from the file
if ~isempty(dataindex)
    if VorW==1
        [data,name,t,~]=gethdf5vital(hdf5file,varname);
    elseif VorW==2
        [data,name,t,~]=gethdf5wave(hdf5file,varname);
    end
else
    dataout = [];
    vt = [];
    varname = [];
    return
end

% Scale the data
data = scaledata(hdf5file, name, data);

%% Merge with global times
% Read in global time stamps
globaltimes = createglobaltimestamps(hdf5file,VorW); % (ms)
% Create fake data to go with global time stamps and store in struct
datamerge(1).x = nan*ones(size(globaltimes));
datamerge(1).t = globaltimes; % for waveforms, these are x 10^12 (ms)
datamerge(1).name = 'Global_Times';
% Take data from variable of interest and store it in the struct
datamerge(2).x = data;
datamerge(2).t = t; % for waveforms, these are x 10^12 (ms)
datamerge(2).name = varname;
% Convert to matrix format with consistent time stamps
[vdata,vt]=vdataformat(datamerge);
% Keep only the data from the variable of interest
dataout = vdata(:,2);

end

function data = scaledata(hdf5file, namesofinterest, data)
    scalematrix = zeros(length(namesofinterest),1);
    for n=1:length(namesofinterest)
        try
            scalematrix(n) = double(h5readatt(hdf5file,[namesofinterest{n} '/data'],'Scale'));
        catch
            scalematrix(n) = 0;
        end
        % For layout version 3, scale is simply a multiplicative factor for the original value. To get the real value, you divide by scale. For layout version 4.0, a real value of 1.2 is stored as 12 with a scale of 1, where scale is stored as the power of 10, so to convert from 12 back to 1.2, you need to divide by 10^scale. Later in this code, when we are actually plotting the data, we divide by scale
        try
            layoutversion = h5readatt(hdf5file,'/','Layout Version');
        catch
            layoutversion = "Doug's Layout";
        end
        if ischar(layoutversion)
            majorversion = str2num(layoutversion(1));
            if majorversion~=3
                scalematrix(n) = 10^scalematrix(n);
            end
        else
            if str2double(layoutversion{1}(1)) ~= 3 
                scalematrix(n) = 10^scalematrix(n);
            end
        end
        data(:,n) = data(:,n)/scalematrix(n);
    end
end