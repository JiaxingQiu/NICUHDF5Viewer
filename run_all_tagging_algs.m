function run_all_tagging_algs(filename,info,algstorun)
nalgs = 31;
if isempty(algstorun)
    algstorun = ones(nalgs,1);
end
if ischar(algstorun)
    algstorun = str2num(char(algstorun));
end
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
firstindex = find(algstorun,1);

% This isn't initializing the results file values in any way - it is just
% filling a place in the initial run of the algorithm
result_name = [];
result_data = [];
result_tags = [];
result_tagcolumns = [];
result_tagtitle = [];
result_qrs = [];

for i=1:length(algstorun)
    if algstorun(i)
        if isempty(isfirst)
            isfirst = firstindex==i;
        end
        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst] = runalg(filename,info,i,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
    end
end

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

function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst] = runalg(filename,info,algnum,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs)
    [algdispname,algmask_current] = algmask;
    algnum1 = algnum;
    algnum = algmask_current(algnum1);
    
    resultname = {...
        '',1;...
        '',1;...
        '',1;...
        '/Results/CUartifact',1;...
        '/Results/WUSTLartifact',1;...
        '/Results/Brady<100',2;...
        '/Results/Desat<80',2;...
        '/Results/Apnea-I',1;...
        '/Results/Apnea-II',1;...
        '/Results/Apnea-III',1;...
        '/Results/Apnea-NoECG',1;...
        '/Results/Apnea',1;... % this algorithm doesn't exist on this git branch
        '/Results/PeriodicBreathing-I',2;...
        '/Results/PeriodicBreathing-II',2;...
        '/Results/PeriodicBreathing-III',2;...
        '/Results/PeriodicBreathing-NoECG',2;...
        '/Results/PeriodicBreathing',1;... % this algorithm doesn't exist on this git branch
        '/Results/Brady<100-Pete',2;...
        '/Results/Desat<80-Pete',2;...
        '/Results/BradyDesat',2;...
        '/Results/BradyDesatPete',2;...
        '/Results/ABDPete-NoECG',3;...
        '/Results/ABDPete',2;... % this algorithm doesn't exist on this git branch
        '/Results/HR',1;...
        '/Results/DataAvailable:Pulse',2;...
        '/Results/DataAvailable:HR',2;...
        '/Results/DataAvailable:SPO2_pct',2;...
        '/Results/DataAvailable:Resp',2;...
        '/Results/DataAvailable:ECGI',2;...
        '/Results/DataAvailable:ECGII',2;...
        '/Results/DataAvailable:ECGIII',2};
    
    resultname = resultname(algmask_current,:);
    
        
    % Find out if this algorithm has already been run. If it has, but this is the first alg on the list, load in the data that the program expects
    shouldrun = shouldrunalgorithm(filename,algnum1,resultname,algdispname(algmask_current,:),result_tagtitle,result_qrs);
    if ~shouldrun
        return
    end
    
    pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
    tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
    msgboxtitle = 'Tagging';

    msgbox(['Running algorithm ' num2str(algnum1) ' of ' num2str(size(algmask_current,2)) ': ' algdispname{algnum,1} ' v' num2str(algdispname{algnum,2})],msgboxtitle,'modal');
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
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,80,pmin,tmin);
            case 8 
                % Apnea detection algorithm using lead I
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,1,result_qrs);
            case 9
                % Apnea detection algorithm using lead II
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,2,result_qrs);
            case 10
                % Apnea detection algorithm using lead III
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,3,result_qrs);
            case 11
                % Apnea detection algorithm using no EKG lead
                [result,t_temp,tag,tagcol] = apneadetector(info,0,result_qrs);
            case 12
                % Apnea detection algorithm using all EKG leads
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,[],result_qrs);
            case 13
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead I
                [result,t_temp,tag,tagcol] = periodicbreathing(info,1,result_tagtitle,result_data);
            case 14
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead II
                [result,t_temp,tag,tagcol] = periodicbreathing(info,2,result_tagtitle,result_data);
            case 15
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead III
                [result,t_temp,tag,tagcol] = periodicbreathing(info,3,result_tagtitle,result_data);
            case 16
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with no ecg lead
                [result,t_temp,tag,tagcol] = periodicbreathing(info,0,result_tagtitle,result_data);
            case 17
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with all EKG leads
                [result,t_temp,tag,tagcol] = periodicbreathing(info,[],result_tagtitle,result_data);
            case 18
                % Pete's bradycardia detection algorithm: Bradys are <100 for ECG HR for at least 4 seconds. Joining rule for bradys is 4 seconds
                [result,t_temp,tag,tagcol] = bradydetector(info,100,4,4000);
            case 19
                % Pete's Desat detection algorithm: <80% for at least 10 seconds if two of those events happen within 10 seconds of eachother, join them together as one event
                [result,t_temp,tag,tagcol] = desatdetector(info,80,10,10000);
            case 20
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesat(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 21
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesatpete(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 22
                % ABD Algorithm with a 30 second threshold. Used Pete's B and D tags along with Apnea-NoECG
                [result,t_temp,tag,tagcol] = abd(info,30000,result_tags,result_tagcolumns,result_tagtitle,result_qrs,0);
            case 23
                % ABD Algorithm with a 30 second threshold. Used Pete's B and D tags along with Apnea
                [result,t_temp,tag,tagcol] = abd(info,30000,result_tags,result_tagcolumns,result_tagtitle,result_qrs,1);
            case 24
                % Store HR Vital Sign
                [result,t_temp,tag,tagcol] = pullHRdata(info);
            case 25
                % Determine when a pulse signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'Pulse',1);
            case 26
                % Determine when a hr signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'HR',1);
            case 27
                % Determine when a spo2% signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'SPO2_pct',1);
            case 28
                % Determine when a resp signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'Resp',0);
            case 29
                % Determine when an ECGI signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGI',0);
            case 30
                % Determine when an ECGII signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGII',0);
            case 31
                % Determine when an ECGIII signal exists
                [result,t_temp,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGIII',0);
        end
        if exist('tagcol')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,resultname(algnum1,:),result,t_temp,tag,tagcol,[]);
                isfirst = 0;
            else
                if ~isempty(tagcol)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(resultname(algnum1,:),result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs); % Must subtract 3 for resultname because qrs detection doesn't have a resultname
                end
            end
        end
        if exist('qrs')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,algdispname(algnum,:),[],[],[],[],qrs);
                isfirst = 0;
            else
                if ~isempty(qrs)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
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
        pause(1)
    end

end