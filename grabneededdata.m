function [data,vt,varname,fs] = grabneededdata(filename,vdata,vname,vt,signame)
% grabneededdata pulls the desired variable from pre-loaded data if
% pre-loaded data is available - otherwise it loads the desired data.
%
% hdf5file: a string with the full path of the file of interest
%
% signame can be any one of the following:
%  'Pulse'
%  'HR'
%  'SPO2_pct'
%  'Resp'
%  'ECGI'
%  'ECGII'
%  'ECGIII'

if isempty(vdata)
    [data,vt,varname] = loadsignal(filename, signame);
else
    % Get the list of all possible variable strings that go with 'Pulse'
    load('X:\Amanda\NICUHDF5Viewer\VariableNames','VariableNames')
    varnamestruct = getfield(VariableNames,signame);
    
    % Find out which of the variable names in the file matches with the desired signame list
    dataindex = [];
    for i = 1:length(varnamestruct)
        varname = varnamestruct(i).Name;
        if sum(ismember(vname,varname))
            dataindex = ismember(vname,varname);
            break
        end
    end
    if isempty(dataindex)
        data = [];
        vt = [];
        varname =[];
        fs = [];
        return
    end
    data = vdata(:,dataindex);
end

% If there isn't data for the variable of interest
if isempty(vt)
    data = [];
    varname =[];
    start = [];
    fs = [];
    return
end

% Get start time and sampling frequency
try
    fs = double(h5readatt(filename,varname,'Sample Frequency (Hz)'));
catch
    rps = double(h5readatt(filename,varname,'Readings Per Sample'));
    samp_pd = double(h5readatt(filename,varname,'Sample Period (ms)'))/1000;
    fs = rps/samp_pd;
end