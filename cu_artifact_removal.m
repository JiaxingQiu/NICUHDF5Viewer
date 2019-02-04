function [results,vt,tag,tagname] = cu_artifact_removal(filename,vdata,vname,t,pmin,tmin)
% Columbia University artifact removal algorithm created by Joe Isler. The
% algorithm is described here:
%
% "HR is compared with PR and data are considered valid only if the
% difference between HR and lagged PR is > 1 standard deviation from 1h
% smoothed HR." - Joe Isler

% I don't know what constitutes "smoothed HR," so I will just use raw HR
% here - I talked to Joe and he said it was boxcar smoothing for 1 hr
 
% INPUT:
% filename: char array path to hdf5 file
% vdata:    if it is empty, grabneededdata will extract the needed data
% vname:    if it is empty, grabneededdata will extract the needed data
% t:        if it is empty, grabneededdata will extract the needed data
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

% Load in the pulse rate and heart rate signals
[spo2rdata,~,~,~] = grabneededdata(filename,vdata,vname,t,'Pulse');
[hrdata,vt,~,fs] = grabneededdata(filename,vdata,vname,t,'HR');
if isempty(vt)
    return
end

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

% artifact = abs(hrdata-spo2rdata)>thresh;

% plot(spo2rdata,'Color',[0.5843 0.5157 0.9882])
% hold on
% plot(hrdata,'b')

% for q=1:numsamps
%     if artifact(q)
%         fillbar(q)
%     end
% end

% Tag the Artifacts
[tag,tagname]=threshtags(~artifact,vt,0.5,pmin,tmin);

% Output the artifact timeseries
results = artifact;
end

function fillbar(e)
x1 = e-1;
x2 = e;
y2 = [0 250];
h = fill([x1 x1 x2 x2], [y2 fliplr(y2)], [0.5843 0.8157 0.9882],'EdgeColor','none');
alpha(h,0.5);
hold on
end
