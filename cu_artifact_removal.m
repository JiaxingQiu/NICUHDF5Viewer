function [results,vt,tag,tagname] = cu_artifact_removal(info,pmin,tmin)
% Columbia University artifact removal algorithm created by Joe Isler. The
% algorithm is described here:
%
% "HR is compared with PR and data are considered valid only if the
% difference between HR and lagged PR is > 1 standard deviation from 1h
% smoothed HR." - Joe Isler

% I don't know what constitutes "smoothed HR," so I will just use raw HR
% here - I talked to Joe and he said it was boxcar smoothing for 1 hr
 
% INPUT:
% info:     from getfileinfo - if empty, it will go get it
% pmin:     minimum number of points below threshold (default one)
% tmin:     time gap between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for artifact and 0 for no artifact
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%

% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];

% Load in the pulse rate and heart rate signals
[data,~,info] = getfiledata(info,{'Pulse','HR'});
spo2index = strcmp({data.fixedname},'Pulse')==1;
hrindex = strcmp({data.fixedname},'HR')==1;
if isempty(spo2index) || isempty(hrindex)
    return
end
[datamatrix,vt,~,~] = formatdata(data,info,3,0);
spo2rdata = datamatrix(:,spo2index);
hrdata = datamatrix(:,hrindex);
fs = data.fs;


% Initialize artifact array
numsamps = length(spo2rdata);
artifact = zeros(numsamps,1);

% Create 1 hour smoothed heart rate
onehrsamples = round(60*60*fs); % 60 min of samples
hrdata = smoothdata(hrdata,'movmean',onehrsamples);

% Run Joe Isler's Artifact Detection Algorithm
for n=1:numsamps
    if n>onehrsamples
        stdev = std(hrdata((n-onehrsamples):n));
        if abs(hrdata(n)-spo2rdata(n))>stdev
            artifact(n) = 1;
        end
    else
        artifact(n) = 1;
    end
end

% Tag the Artifacts
[tag,tagname]=threshtags(~artifact,vt,0.5,pmin,tmin);

% Output the artifact timeseries
% results = artifact;
results = [];
vt = [];
end

function fillbar(e)
x1 = e-1;
x2 = e;
y2 = [0 250];
h = fill([x1 x1 x2 x2], [y2 fliplr(y2)], [0.5843 0.8157 0.9882],'EdgeColor','none');
alpha(h,0.5);
hold on
end
