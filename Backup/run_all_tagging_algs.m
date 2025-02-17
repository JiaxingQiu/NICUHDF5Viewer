function run_all_tagging_algs(filename,info,algstorun)

[algdispname,algmaskout,resultname] = algmask;
nalgs=size(algdispname,1);
if isempty(algstorun)
     algstorun=zeros(nalgs,1);
     algstorun(algmaskout)=1;
%     [~,algmaskout,~] = algmask;
%     algstorun = ones(length(algmaskout),1);
end
if ischar(algstorun)
     algstorun=zeros(nalgs,1);
     algstorun(algmaskout)=1;
%     [~,algmaskout,~] = algmask;
%     algstorun = ones(length(algmaskout),1);
end
algnum=find(algstorun>0);
algnum(algnum>nalgs)=[];
newalg=length(algnum);
if newalg==0,return,end

if ischar(info)
    info = str2num(char(info));
end
if isempty(info)
    try
        info=getfileinfo(filename);
    catch
        return
    end
end

isfirst = [];
%firstindex = find(algstorun,1);
firstindex=algnum(1);

% This isn't initializing the results file values in any way - it is just
% filling a place in the initial run of the algorithm
result_name = [];
result_data = [];
result_tags = [];
result_tagcolumns = [];
result_tagtitle = [];
result_qrs = [];

% Find the Log Filename
if contains(filename,'.hdf5')
    logfilename = strrep(filename,'.hdf5','_log.mat');
elseif contains(filename,'.dat')
    logfilename = strrep(filename,'.dat','_log.mat');
elseif contains(filename,'.mat')
    logfilename = strrep(filename,'.mat','_log.mat');
end
log = struct;
% fid = fopen(logfilename,'w'); % Overwrite previous log file
% fprintf(fid,'%s\r\n',['FILE: ' filename]);
% fprintf(fid,'%23s\n',datestr(clock,'YYYY/mm/dd HH:MM:SS'));

% Add algorithm folders to path
if ~isdeployed
    addpath([fileparts(which('call_hctsa.m')) '\hctsa'])
    addpath([fileparts(which('qrsdetector.m')) '\Apnea'])
    addpath([fileparts(which('qrsdetector.m')) '\QRSDetection'])
end

% for i=1:length(algstorun)
%     if algstorun(i)
for k=1:newalg
    i=algnum(k);
    if k==1,isfirst=true;end
%     if algstorun(i)
%         if isempty(isfirst)
%             isfirst = firstindex==i;
%         end
     [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst,log] = runalg(filename,info,i,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,log);
%    end
end

%Add time of zero to empty log entries
for i=1:length(log)
    try
        if isempty(log(i).time)
            log(i).time=0;
        end
    end
end      
    
% fclose(fid);
save(logfilename,'log')

% Find the Result Filename
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
elseif contains(filename,'.dat')
    resultfilename = strrep(filename,'.dat','_results.mat');
elseif contains(filename,'.mat')
    resultfilename = strrep(filename,'.mat','_results.mat');
end

% Save the Results
msgbox('Saving the results','Tagging','modal');
info = rmfield(info,'alldata');
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','result_data','result_qrs','info');

w = msgbox('Tagging Algorithms Complete','Tagging','modal');
pause(1);
if isvalid(w)
    delete(w);
end
end

function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst,log] = runalg(filename,info,algnum,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,log)
    [algdispname,algmask_current,resultname] = algmask;
    algnum1 = algnum;
    algnum = algmask_current(algnum1);
    resultname = resultname(algmask_current,:);
    aname=algdispname(algnum1,:);
    rname=resultname(algnum1,:);
        
    % Find out if this algorithm has already been run. If it has, but this is the first alg on the list, load in the data that the program expects
    shouldrun = shouldrunalgorithm(filename,algnum1,resultname,algdispname(algmask_current,:),result_tagtitle,result_qrs);
    if ~shouldrun
        log = addtolog(log,filename,rname,aname,'Previously run',[]);
        log(end).time=0;
        return
    end

    pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
    tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
    msgboxtitle = 'Tagging';

    msgbox(['Running algorithm ' num2str(algnum1) ' of ' num2str(size(algmask_current,2)) ': ' algdispname{algnum,1} ' v' num2str(algdispname{algnum,2})],msgboxtitle,'modal');
    tic
    try
        switch algnum
            case 1
                % QRS Detection with ECGI
                qrs = qrsdetector(info,1,algdispname(algnum,2));
            case 2
                % QRS Detection with ECGII
                qrs = qrsdetector(info,2,algdispname(algnum,2));
            case 3
                % QRS Detection with ECGIII
                qrs = qrsdetector(info,3,algdispname(algnum,2));
            case 4
                % Run and plot Columbia artifact removal, which works by comparing HR vs SPO2-R. Removes data which has a discrepancy between sensors.
                [result,t_temp,tag,tagcol] = cu_artifact_removal(info,pmin,tmin);
            case 5
                % Run and plot WashU artifact removal, which works by removing low or missing SPO2-% data, then removing big jumps (of >3%)
                [result,t_temp,tag,tagcol] = wustl_artifact_removal(info,50,pmin,tmin); % 50 is the threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
            case 6
                % Run a bradycardia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = bradydetector(info,100,pmin,tmin);
            case 7 
                % Apnea detection algorithm using lead I
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,1,result_qrs);
            case 8
                % Apnea detection algorithm using lead II
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,2,result_qrs);
            case 9
                % Apnea detection algorithm using lead III
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,3,result_qrs);
            case 10
                % Apnea detection algorithm using no EKG lead
                [result,t_temp,tag,tagcol] = apneadetector(info,0,result_qrs);
            case 11
                % Apnea detection algorithm using all EKG leads
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,[],result_qrs);
            case 12
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead I
                [result,t_temp,tag,tagcol] = periodicbreathing(info,1,result_tagtitle,result_data);
            case 13
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead II
                [result,t_temp,tag,tagcol] = periodicbreathing(info,2,result_tagtitle,result_data);
            case 14
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead III
                [result,t_temp,tag,tagcol] = periodicbreathing(info,3,result_tagtitle,result_data);
            case 15
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with no ecg lead
                [result,t_temp,tag,tagcol] = periodicbreathing(info,0,result_tagtitle,result_data);
            case 16
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with all EKG leads
                [result,t_temp,tag,tagcol] = periodicbreathing(info,[],result_tagtitle,result_data);
            case 17
                % Pete's bradycardia detection algorithm: Bradys are <100 for ECG HR for at least 4 seconds. Joining rule for bradys is 4 seconds
                [result,t_temp,tag,tagcol] = bradydetector(info,100,4,4000);
            case 18
                % Pete's Desat detection algorithm: <80% for at least 10 seconds if two of those events happen within 10 seconds of eachother, join them together as one event
                [result,t_temp,tag,tagcol] = desatdetector(info,80,10,10000,1,1);
            case 19
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesat(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 20
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesatpete(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 21
                % ABD Algorithm using Hoshik's thresholds. Uses Apnea-NoECG
                [result,t_temp,tag,tagcol] = abd(info,result_tags,result_tagcolumns,result_tagtitle,result_qrs,0);
            case 22
                % ABD Algorithm using Hoshik's thresholds. Uses Apnea.
                [result,t_temp,tag,tagcol] = abd(info,result_tags,result_tagcolumns,result_tagtitle,result_qrs,1);
            case 23
                % Store HR Vital Sign
                [result,t_temp,tag,tagcol] = pullHRdata(info);
            case 24
                % Determine when a pulse signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'Pulse',1);
            case 25
                % Determine when a hr signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'HR',1);
            case 26
                % Determine when a spo2% signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'SPO2_pct',1);
            case 27
                % Determine when a resp signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'Resp',0);
            case 28
                % Determine when an ECGI signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGI',0);
            case 29
                % Determine when an ECGII signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGII',0);
            case 30
                % Determine when an ECGIII signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGIII',0);
            case 31
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,75,pmin,tmin, 1, 1);
            case 32
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,76,pmin,tmin, 1, 1);
            case 33
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,77,pmin,tmin, 1, 1);
            case 34
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,78,pmin,tmin, 1, 1);
            case 35
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,79,pmin,tmin, 1, 1);
            case 36
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,80,pmin,tmin, 1, 1);
            case 37
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,81,pmin,tmin, 1, 1);
            case 38
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,82,pmin,tmin, 1, 1);
            case 39
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,83,pmin,tmin, 1, 1);
            case 40
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,84,pmin,tmin, 1, 1);
            case 41
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,85,pmin,tmin, 1, 1);
            case 42
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,86,pmin,tmin, 1, 1);
            case 43
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,87,pmin,tmin, 1, 1);
            case 44
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,88,pmin,tmin, 1, 1);
            case 45
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,89,pmin,tmin, 1, 1);
            case 46
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,90,pmin,tmin, 1, 1);
            case 47
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,91,pmin,tmin, 1, 1);
            case 48
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,92,pmin,tmin, 1, 1);
            case 49
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,93,pmin,tmin, 1, 1);
            case 50
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,94,pmin,tmin, 1, 1);
            case 51
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,95,pmin,tmin, 1, 1);
            case 52
                % Compute the hourly HR mean
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','mean');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'mean','HR');                
            case 53
                % Compute the hourly pulse rate mean
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','mean');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'mean','HR');                
            case 54
                % Compute the hourly SPO2% mean
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','mean');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'mean','SPO2_pct');                                
            case 55
                % Compute the hourly HR std
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','std');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'std','HR');                                
            case 56
                % Compute the hourly pulse rate std
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','std');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'std','Pulse');                                                
            case 57
                % Compute the hourly SPO2% std
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','std');    
                [result,t_temp,tag,tagcol] = call_hctsa(info,'std','SPO2_pct');                                                
            case 58
                % Compute the hourly HR skewness
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','skewness');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'skewness','HR');                                                                
            case 59
                % Compute the hourly pulse rate skewness
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','skewness');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'skewness','Pulse');                                                                                
            case 60
                % Compute the hourly SPO2% skewness
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','skewness');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'skewness','SPO2_pct');                                                                                
            case 61
                % Compute the hourly HR kurtosis
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','kurtosis');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'kurtosis','HR');                                                                                
            case 62
                % Compute the hourly pulse rate kurtosis
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','kurtosis');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'kurtosis','Pulse');                                                                                
            case 63
                % Compute the hourly SPO2% kurtosis
%                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','kurtosis');
                [result,t_temp,tag,tagcol] = call_hctsa(info,'kurtosis','SPO2_pct');                                                                
            case 64
                % Compute max cross corr every 10 minutes, using the last 10 min of data (min xcorr & lags are also computed. All values are stored in tags.)
                [result,t_temp,tag,tagcol] = crosscorrelation(info,'HR','SPO2_pct');
            case 65
                % Compute max cross corr every 10 minutes, using the last 10 min of data (min xcorr & lags are also computed. All values are stored in tags.)
                [result,t_temp,tag,tagcol] = crosscorrelation(info,'Pulse','SPO2_pct');
            case 66
                % HCTSA Algorithm: How Suprised?
                [result,t_temp,tag,tagcol] = call_hctsa(info,'FC_Surprise','HR');
            case 67
                % HCTSA Algorithm: Probability of successive increases
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_MotifTwo','HR');
            case 68
                % HCTSA Algorithm: STD of random walk
                [result,t_temp,tag,tagcol] = call_hctsa(info,'PH_Walker','SPO2_pct');
            case 69
                % HCTSA Algorithm: Average threshold
                [result,t_temp,tag,tagcol] = call_hctsa(info,'EX_MovingThreshold','HR');
            case 70
                % HCTSA Algorithm: Average thrshold
                [result,t_temp,tag,tagcol] = call_hctsa(info,'EX_MovingThreshold','SPO2_pct');
            case 71
                % HCTSA Algorithm: Distribution HR SD (CV?)
                [result,t_temp,tag,tagcol] = call_hctsa(info,'DN_cv','HR');
            case 72
                % HCTSA Algorithm: Distribution HR Skewness
                [result,t_temp,tag,tagcol] = call_hctsa(info,'DN_Cumulants','HR');
            case 73
                % HCTSA Algorithm: Distribution HR Max
                [result,t_temp,tag,tagcol] = call_hctsa(info,'DN_Quantile','HR');
            case 74
                % HCTSA Algorithm: Symbolic transforms HR autocorrelation
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_TransitionMatrix_tau3','HR');
            case 75
                % HCTSA Algorithm: Symbolic transforms HR entropy
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_MotifThree_quantile','HR');
            case 76
                % HCTSA Algorithm: HR wavelet autoregressive model
                [result,t_temp,tag,tagcol] = call_hctsa(info,'MF_arfit','HR');
            case 77
                % HCTSA Algorithm: Symbolic transforms HR first differences of coarsely-grained series
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_MotifThree_diffquant','HR');
            case 78
                % HCTSA Algorithm: Std of 17th derivative of time series
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SY_StdNthDer','HR');
            case 79
                % HCTSA Algorithm: Distribution SpO2 mean
                [result,t_temp,tag,tagcol] = call_hctsa(info,'DN_RemovePoints','SPO2_pct');
            case 80
                % HCTSA Algorithm: Symbolic transforms SpO2 interquartile ranges of ??
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_BinaryStats','SPO2_pct');
            case 81
                % HCTSA Algorithm: SpO2 wavelet autoregressive model
                [result,t_temp,tag,tagcol] = call_hctsa(info,'MF_arfit','SPO2_pct');
            case 82
                % HCTSA Algorithm: Symbolic transforms SpO2 eigenvalues of transition matrix
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_TransitionMatrix_tau2','SPO2_pct');
            case 83
                % HCTSA Algorithm: Correlation SpO2 autocorrelation coefficient at lag = 4
                [result,t_temp,tag,tagcol] = call_hctsa(info,'CO_AutoCorr','SPO2_pct');
            case 84
                % HCTSA Algorithm: Symbolic transforms SpO2 entropy
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_MotifThree_diffquant','SPO2_pct');
            case 85
                % HCTSA Algorithm: Symbolic transforms SpO2 binary state transitions
                [result,t_temp,tag,tagcol] = call_hctsa(info,'SB_TransitionMatrix_tau1','SPO2_pct');
            case 86
                % HCTSA Algorithm: Stationarity SpO2 ratio of minimum to range
                [result,t_temp,tag,tagcol] = call_hctsa(info,'ST_LocalExtrema_SPO2','SPO2_pct');
            case 87
                % HCTSA Algorithm: Stationary HR min
                [result,t_temp,tag,tagcol] = call_hctsa(info,'ST_LocalExtrema_HR','HR');
            case 88
                % HCTSA Algorithm: Correlation HR mean
                [result,t_temp,tag,tagcol] = call_hctsa(info,'CO_tc3_HR','HR');
            case 89
                % HCTSA Algorithm: Correlation SPO2 mean
                [result,t_temp,tag,tagcol] = call_hctsa(info,'CO_tc3_SPO2','SPO2_pct');
            case 90
                % Run a bradycardia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = bradydetector(info,90,pmin,tmin);
            case 91
                % Run a bradycardia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = bradydetector(info,80,pmin,tmin);
            case 92
                % Run a bradycardia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = bradydetector(info,70,pmin,tmin);
            case 93
                % Run a hyperoxemia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,95,pmin,tmin, 0,1);
            case 94
                % Run a hyperoxemia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,98,pmin,tmin, 0,1);
            case 95
                % Run a hyperoxemia detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = flatdetector(info,'Resp',10);
        end
        algtime=toc;
        if exist('tagcol','var')
            if isfirst
                [isfile,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresults(filename);
                isfirst = 0;
                if ~isfile && ~isempty(tagcol) % If there is no results file and we have something to put in one, create a file!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile(rname,result,t_temp,tag,tagcol,[]);
                    log = addtolog(log,filename,rname,aname,'Success',[]);
                elseif ~isfile % If there is no results file and we don't have something to put in one, don't create one yet - wait!
                    isfirst = 1;
                    log = addtolog(log,filename,rname,aname,'Cleanly exited',[]);
                elseif isfile && ~isempty(tagcol) % If there is a results file and we have something to put in it, put it in!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(rname,result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);                    
                    % Note: If there is a results file and we don't have anything to put in it, there is nothing more to do
                    log = addtolog(log,filename,rname,aname,'Success',[]);
                    c1=find(contains(tagcol,'MinCrossCorr'),1);
%Add result tag for MinCrossCorr                    
                    if ~isempty(c1)
                        c2=find(contains(tagcol,'Value'),1);                    
                        tagcol{c2}='MaxCrossCorr';
                        tagcol{c1}='Value';
                        rname1=rname;
                        rname1{1}=strrep(rname{1},'Max','Min');
                        aname1=aname;                        
                        aname1{1}=strrep(aname{1},'Max','Min');                                                
                        disp(rname1)
                        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(rname1,result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);                                        
                        log = addtolog(log,filename,rname1,aname1,'Success',[]);                    
                    end
                end                
            elseif ~isempty(tagcol)
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(rname,result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                log = addtolog(log,filename,rname,aname,'Success',[]);
            else
                log = addtolog(log,filename,rname,aname,'Cleanly exited',[]);
            end
        end
        if exist('qrs','var')
            if isfirst
                [isfile,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresults(filename);
                isfirst = 0;
                if ~isfile && ~isempty(qrs) % If there is no results file and we have something to put in one, create a file!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile([],[],[],[],[],qrs);
                    log = addtolog(log,filename,rname,aname,'QRS Success',[]);
                elseif ~isfile % If there is no results file and we don't have something to put in one, don't create one yet - wait!
                    isfirst = 1;
                    log = addtolog(log,filename,rname,aname,'QRS Cleanly exited',[]);
                elseif isfile && ~isempty(qrs) % If there is a results file and we have something to put in it, put it in!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                    % Note: If there is a results file and we don't have anything to put in it, there is nothing more to do
                    log = addtolog(log,filename,rname,aname,'QRS Success',[]);
                else
                    log = addtolog(log,filename,rname,aname,'QRS Cleanly exited',[]);
                end
            else
                if ~isempty(qrs)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                    log = addtolog(log,filename,rname,aname,'QRS Success',[]);
                else
                    log = addtolog(log,filename,rname,aname,'QRS Cleanly exited',[]);
                end
            end
        end
    catch ME
        message = ['Failure running algorithm ' num2str(algnum1) ' of ' num2str(size(algmask_current,2)) ': ' algdispname{algnum,1} '. Filename: ' filename '. Continuing running tagging algorithms.'];
        msgbox(message,msgboxtitle,'modal');
        disp(message)
        disp(['Identifier: ' ME.identifier])
        disp(['Message: ' ME.message])
        for m=1:length(ME.stack)
            disp(['File: ' ME.stack(m).file])
            disp(['Name: ' ME.stack(m).name])
            disp(['Line: ' num2str(ME.stack(m).line)])
        end
        disp(newline)
        log = addtolog(log,filename,rname,aname,'Error',ME);
        pause(1)
        algtime=toc;
    end
    
    r=length(log);
    if r>0
        log(r).time=algtime;
        algorithm=log(r).algorithm{1};        
        disp(algorithm)
        disp(algtime)
    end

end

function log = addtolog(log,filename,result_name,algdispname,success,error)
    if isfield(log,'algorithm')
        r = length(log)+1;
    else
        r = 1;
    end
    if strcmp(result_name(1,1),'')
        log(r).algorithm = algdispname(1,1);
        log(r).version = algdispname{1,2};
    else
        log(r).algorithm = result_name(1,1);
        log(r).version = result_name{1,2};
    end
    log(r).success = success;
    log(r).error = error;
    log(r).filename = filename;
end