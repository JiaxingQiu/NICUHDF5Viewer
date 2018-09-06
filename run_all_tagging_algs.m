function run_all_tagging_algs(filename,vdata,vname,vt,wdata,wname,wt)
% fs = sampling frequency
% Artifact Removal Comparison between Columbia and WashU. WashU is in red,
% CU is in blue. CU uses HR/SPO2-R. WashU uses SPO2-%.

% % Run cross correlation
% [xcorr_30,vt,zt] = xcorr_hr_spo2(filename);
% addtoresultsfile(filename,'/Results/CrossCorrelation',xcorr_30,zt);

pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
nalgs = 8; % number of algorithms
msgboxtitle = 'Tagging';

% Run and plot Columbia artifact removal, which works by comparing HR vs
% SPO2-R. Removes data which has a discrepancy between sensors.
msgbox(['Running algorithm 1 of ' num2str(nalgs) ': CU Artifact'],msgboxtitle,'modal');
try
    [cu_artifact,vt] = cu_artifact_removal(filename,vdata,vname,vt);
    [tag,tagname]=threshtags(~cu_artifact,vt,0.5,pmin,tmin);
    if ~isempty(tag)
        addtoresultsfile2(filename,'/Results/CUartifact',cu_artifact,vt,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 1 of ' num2str(nalgs) ': CU Artifact. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% Run and plot WashU artifact removal, which works by removing low or
% missing SPO2-% data, then removing big jumps (of >3%)
msgbox(['Running algorithm 2 of ' num2str(nalgs) ': WUSTL Artifact'],msgboxtitle,'modal');
try
    spo2min = 50; % Threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
    [wu_artifact,vt] = wustl_artifact_removal(filename,spo2min,vdata,vname,vt);
    [tag,tagname]=threshtags(~wu_artifact,vt,0.5,pmin,tmin);
if ~isempty(tag)
    addtoresultsfile2(filename,'/Results/WUSTLartifact',wu_artifact,vt,tag,tagname);
end
catch
    msgbox(['Failure running algorithm 2 of ' num2str(nalgs) ': WUSTL Artifact. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% Run a bradycardia detection algorithm
msgbox(['Running algorithm 3 of ' num2str(nalgs) ': Brady Detection'],msgboxtitle,'modal');
try
    bradythresh = 100;
    [brady100,vt,tag,tagname] = bradydetector(filename,vdata,vname,vt,bradythresh,pmin,tmin);
    if ~isempty(brady100)
        addtoresultsfile2(filename,'/Results/Brady<=100',brady100,vt,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 3 of ' num2str(nalgs) ': Brady Detection. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% Run a desaturation detection algorithm
msgbox(['Running algorithm 4 of ' num2str(nalgs) ': Desat Detection'],msgboxtitle,'modal');
try
    desatthresh = 80;
    [desat80,vt,tag,tagname] = desatdetector(filename,vdata,vname,vt,desatthresh,pmin,tmin);
    if ~isempty(desat80)
        addtoresultsfile2(filename,'/Results/Desat<=80',desat80,vt,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 4 of ' num2str(nalgs) ': Desat Detection. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end


% Run the apnea detection algorithm using lead I
msgbox(['Running algorithm 5 of ' num2str(nalgs) ': Apnea Detection with ECG Lead I'],msgboxtitle,'modal');
try
    [apnea,pt,tag,tagname] = apneadetector(filename,1,wdata,wname,wt);
    if ~isempty(apnea)
        addtoresultsfile2(filename,'/Results/Apnea-I',apnea,pt*1000,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 5 of ' num2str(nalgs) ': Apnea Detection with ECG Lead I. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% Run the apnea detection algorithm using lead II
msgbox(['Running algorithm 6 of ' num2str(nalgs) ': Apnea Detection with ECG Lead II'],msgboxtitle,'modal');
try
    [apnea,pt,tag,tagname] = apneadetector(filename,2,wdata,wname,wt);
    if ~isempty(apnea)
        addtoresultsfile2(filename,'/Results/Apnea-II',apnea,pt*1000,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 6 of ' num2str(nalgs) ': Apnea Detection with ECG Lead II. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% Run the apnea detection algorithm using lead III
msgbox(['Running algorithm 7 of ' num2str(nalgs) ': Apnea Detection with ECG Lead III'],msgboxtitle,'modal');
try
    [apnea,pt,tag,tagname] = apneadetector(filename,3,wdata,wname,wt);
    if ~isempty(apnea)
        addtoresultsfile2(filename,'/Results/Apnea-III',apnea,pt*1000,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 7 of ' num2str(nalgs) ': Apnea Detection with ECG Lead III. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

% % Run the periodic breathing algorithm
% msgbox(['Running algorithm 8 of ' num2str(nalgs) ': Periodic Breathing.'],msgboxtitle,'modal');
% [pb_indx,pb_time,tag,tagname] = periodicbreathing(filename);
% if ~isempty(pb_indx)
% 	addtoresultsfile2(filename,'/Results/PeriodicBreathing',pb_indx,pb_time,tag,tagname);
% end

% Run a bradycardia detection algorithm
msgbox(['Running algorithm 8 of ' num2str(nalgs) ': Brady Detection Pete'],msgboxtitle,'modal');
try
    bradythresh = 100;
    [brady100,vt,tag,tagname] = bradydetector(filename,vdata,vname,vt,bradythresh,4,4);
    if ~isempty(brady100)
        addtoresultsfile2(filename,'/Results/Brady<=100-Pete',brady100,vt,tag,tagname);
    end
catch
    msgbox(['Failure running algorithm 9 of ' num2str(nalgs) ': Brady Detection Pete. Continuing running tagging algorithms.'],msgboxtitle,'modal');
end

msgbox('Tagging Algorithms Complete',msgboxtitle,'modal');

end