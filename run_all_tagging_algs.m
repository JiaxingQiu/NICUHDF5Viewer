function run_all_tagging_algs(filename,vdata,vname,vt,wdata,wname,wt,algstorun)
% This runs through 
if ~exist('algstorun','var')
    algstorun = ones(nalgs,1);
end

for i=1:length(algstorun)
    if algstorun(i)
        runalg(filename,vdata,vname,vt,wdata,wname,wt,i);
    end
end

msgbox('Tagging Algorithms Complete','Tagging','modal');
end

function runalg(filename,vdata,vname,vt,wdata,wname,wt,algnum)
    algdispname = {'CU Artifact';...
        'WUSTL Artifact';...
        'Brady Detection';...
        'Desat Detection';...
        'Apnea Detection with ECG Lead I';...
        'Apnea Detection with ECG Lead II';...
        'Apnea Detection with ECG Lead III';...
        'Apnea Detection with No ECG Lead';...
        'Periodic Breathing';...
        'Brady Detection Pete';...
        'Desat Detection Pete'};
    
    resultname = {'/Results/CUartifact';...
        '/Results/WUSTLartifact';...
        '/Results/Brady<100';...
        '/Results/Desat<80';...
        '/Results/Apnea-I';...
        '/Results/Apnea-II';...
        '/Results/Apnea-III';...
        '/Results/Apnea-NoECG';...
        '/Results/PeriodicBreathing';...
        '/Results/Brady<100-Pete';...
        '/Results/Desat<80-Pete'};
    
    pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
    tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
    msgboxtitle = 'Tagging';

    msgbox(['Running algorithm ' num2str(algnum) ' of ' num2str(length(algdispname)) ': ' algdispname{algnum}],msgboxtitle,'modal');
    try
        switch algnum
            case 1
                % Run and plot Columbia artifact removal, which works by comparing HR vs SPO2-R. Removes data which has a discrepancy between sensors.
                [result,t_temp,tag,tagname] = cu_artifact_removal(filename,vdata,vname,vt,pmin,tmin);
            case 2
                % Run and plot WashU artifact removal, which works by removing low or missing SPO2-% data, then removing big jumps (of >3%)
                [result,t_temp,tag,tagname] = wustl_artifact_removal(filename,50,vdata,vname,vt,pmin,tmin); % 50 is the threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
            case 3
                % Run a bradycardia detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagname] = bradydetector(filename,vdata,vname,vt,99.99,pmin,tmin);
            case 4
                % Run a desaturation detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagname] = desatdetector(filename,vdata,vname,vt,79.99,pmin,tmin);
            case 5 
                % Apnea detection algorithm using lead I
                [result,t_temp,tag,tagname] = apneadetector(filename,1,wdata,wname,wt);
            case 6
                % Apnea detection algorithm using lead II
                [result,t_temp,tag,tagname] = apneadetector(filename,2,wdata,wname,wt);
            case 7
                % Apnea detection algorithm using lead III
                [result,t_temp,tag,tagname] = apneadetector(filename,3,wdata,wname,wt);
            case 8
                % Apnea detection algorithm using no EKG lead
                [result,t_temp,tag,tagname] = apneadetector(filename,0,wdata,wname,wt);
            case 9
                % Mary Mohr's periodic breathing algorithm
                [result,t_temp,tag,tagname] = periodicbreathing(filename);
            case 10
                % Pete's bradycardia detection algorithm: Bradys are <100 for ECG HR for at least 4 seconds. Joining rule for bradys is 4 seconds
                [result,t_temp,tag,tagname] = bradydetector(filename,vdata,vname,vt,99.99,4,4000);
            case 11
                % Pete's Desat detection algorithm: <80% for at least 10 seconds if two of those events happen within 10 seconds of eachother, join them together as one event
                [result,t_temp,tag,tagname] = desatdetector(filename,vdata,vname,vt,79.99,10,10000);
        end
        if ~isempty(result)
            addtoresultsfile2(filename,resultname{algnum},result,t_temp,tag,tagname);
        end
    catch
        msgbox(['Failure running algorithm ' num2str(algnum) ' of ' num2str(length(algdispname)) ': ' algdispname{algnum} '. Continuing running tagging algorithms.'],msgboxtitle,'modal');
        pause(1)
    end

end