function run_all_tagging_algs(filename)
% fs = sampling frequency
% Artifact Removal Comparison between Columbia and WashU. WashU is in red,
% CU is in blue. CU uses HR/SPO2-R. WashU uses SPO2-%.

% % Run cross correlation
% [xcorr_30,vt,zt] = xcorr_hr_spo2(filename);
% addtoresultsfile(filename,'/Results/CrossCorrelation',xcorr_30,zt);

pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!

% Run and plot Columbia artifact removal, which works by comparing HR vs
% SPO2-R. Removes data which has a discrepancy between sensors.
[cu_artifact,vt] = cu_artifact_removal(filename);
[tag,tagname]=threshtags(~cu_artifact,vt,0.5,pmin,tmin);
if ~isempty(tag)
    addtoresultsfile(filename,'/Results/CUartifact',cu_artifact,vt,tag,tagname);
end

% Run and plot WashU artifact removal, which works by removing low or
% missing SPO2-% data, then removing big jumps (of >3%)
spo2min = 50; % Threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
[wu_artifact,vt] = wustl_artifact_removal(filename,spo2min);
[tag,tagname]=threshtags(~wu_artifact,vt,0.5,pmin,tmin);
if ~isempty(tag)
    addtoresultsfile(filename,'/Results/WUSTLartifact',wu_artifact,vt,tag,tagname);
end

% Run a bradycardia detection algorithm
bradythresh = 100;
[brady100,vt,tag,tagname] = bradydetector(filename,bradythresh,pmin,tmin);
if ~isempty(brady100)
    addtoresultsfile(filename,'/Results/Brady<=100',brady100,vt,tag,tagname);
end

% Run a desaturation detection algorithm
desatthresh = 80;
[desat80,vt,tag,tagname] = desatdetector(filename,desatthresh,pmin,tmin);
if ~isempty(desat80)
    addtoresultsfile(filename,'/Results/Desat<=80',desat80,vt,tag,tagname);
end
end
