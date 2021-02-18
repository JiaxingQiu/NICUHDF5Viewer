function [results,vt,tag,tagname] = pullHRdata(info)
% This just pulls the HR data to be stored in the Results file

% INPUT:
% info:      from getfileinfo

% OUTPUT:
% results: binary array of 1 for bradycardia and 0 for no bradycardia
% vt:      UTC time
% tag:     empty placeholder array
% tagname: placeholder array

% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname=cell(6,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Area';
tagname{6}='Minimum';

% Load in the hr signal
[data,~,info] = getfiledata(info,'HR');
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data)
    return
end
hrdata = data.x;
vt = data.t;

% Remove negative HR values
hrdata(hrdata<=1) = nan;
results = hrdata;