function [results,vt,tag,tagname] = wustl_artifact_removal(filename,thresh,vdata,vname,vt,pmin,tmin)
% The WUSTL artifact removal algorithm is described here:
% Epochs with a change greater than 3% between serial data points were 
% judged to be contaminated with motion artifact and were discarded

% INPUT:
% filename: char array path to hdf5 file
% thresh:   threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data
% vdata:    if it is empty, grabneededdata will extract the needed data
% vname:    if it is empty, grabneededdata will extract the needed data
% vt:       if it is empty, grabneededdata will extract the needed data
% pmin:     minimum number of points below threshold (default one)
% tmin:     time gap between crossings to join (default zero)

% OUTPUT:
% results: binary array of 1 for artifact and 0 for no artifact
% vt:      UTC time
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file
%

e_size = 30; % epoch size: the number of samples in each epoch

% Load in the spo2% signal
[spo2data,vt,~] = grabneededdata(filename,vdata,vname,vt,'SPO2_pct');
if isempty(vt)
    results = [];
    return
end

% Initialize artifact array
numsamps = length(spo2data);
nepochs = floor(numsamps/e_size); % The number of epochs, given that each epoch is 60 seconds (i.e. 30 samples)
e_artifact = zeros(nepochs,1); % Epoch artifact: if 1, at least 50% of the epoch has missing data
results = zeros(numsamps,1);

% Run artifact check on each epoch sequentially
for e=1:nepochs
    % Pull out data for just one epoch
    indices = e_size*e-e_size+1:e_size*e;
    epoch = spo2data(indices);
    
    % Check for "missing" data: i.e. nans or low values (<thresh)
    num_nans = sum(isnan(epoch));
    num_lows = sum(epoch<thresh);
    if num_nans+num_lows>e_size/2 % If over 50% of the data in the epoch is bad, mark the epoch as bad
        e_artifact(e) = 1;
%         fillbar(e);
%         hold on
    end
    % Epochs with a change greater than 3% between serial data points were 
    % judged to be contaminated with motion artifact and were discarded
    if sum(abs(diff(epoch))>3)>0
        e_artifact(e) = 1;
%         fillbar(e);
%         hold on
    end
    if e_artifact(e)==1
        results(e*30-29:e*30,1) = e_artifact(e);
    end
end
% plot(spo2data,'r')

% Tag Artifacts
[tag,tagname]=threshtags(~results,vt,0.5,pmin,tmin);

clear spo2data
end

function fillbar(e)
x1 = 30*e-30;
x2 = 30*e;
y2 = [0 250];
h = fill([x1 x1 x2 x2], [y2 fliplr(y2)], [0.85 0.25 0.25],'EdgeColor','none');
alpha(h,0.3);
end
