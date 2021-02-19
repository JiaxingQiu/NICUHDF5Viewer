function run_all_tagging_algs(filename,info,algstorun)
nalgs = 45;
if isempty(algstorun)
    [~,algmaskout,~] = algmask;
    algstorun = ones(length(algmaskout),1);
end
if ischar(algstorun)
    [~,algmaskout,~] = algmask;
    algstorun = ones(length(algmaskout),1);
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
    [algdispname,algmask_current,resultname] = algmask;
    algnum1 = algnum;
    algnum = algmask_current(algnum1);
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
            case 32
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,85,pmin,tmin);
            case 33
                % Run a desaturation detection algorithm which identifies any and all drops < the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,90,pmin,tmin);
            case 34
                % Compute the hourly HR mean
                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','mean');
            case 35
                % Compute the hourly pulse rate mean
                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','mean');
            case 36
                % Compute the hourly SPO2% mean
                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','mean');
            case 37
                % Compute the hourly HR std
                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','std');
            case 38
                % Compute the hourly pulse rate std
                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','std');
            case 39
                % Compute the hourly SPO2% std
                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','std');    
            case 40
                % Compute the hourly HR skewness
                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','skewness');
            case 41
                % Compute the hourly pulse rate skewness
                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','skewness');
            case 42
                % Compute the hourly SPO2% skewness
                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','skewness');
            case 43
                % Compute the hourly HR kurtosis
                [result,t_temp,tag,tagcol] = hourlymetric(info,'HR','kurtosis');
            case 44
                % Compute the hourly pulse rate kurtosis
                [result,t_temp,tag,tagcol] = hourlymetric(info,'Pulse','kurtosis');
            case 45
                % Compute the hourly SPO2% kurtosis
                [result,t_temp,tag,tagcol] = hourlymetric(info,'SPO2_pct','kurtosis');
        end
        if exist('tagcol')
            if isfirst
                [isfile,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresults(filename);
                isfirst = 0;
                if ~isfile && ~isempty(tagcol) % If there is no results file and we have something to put in one, create a file!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile(resultname(algnum1,:),result,t_temp,tag,tagcol,[]);
                elseif ~isfile % If there is no results file and we don't have something to put in one, don't create one yet - wait!
                    isfirst = 1;
                elseif isfile && ~isempty(tagcol) % If there is a results file and we have something to put in it, put it in!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(resultname(algnum1,:),result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                    % Note: If there is a results file and we don't have anything to put in it, there is nothing more to do
                end
            elseif ~isempty(tagcol)
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(resultname(algnum1,:),result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
            end
        end
        if exist('qrs')
            if isfirst
                [isfile,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresults(filename);
                isfirst = 0;
                if ~isfile && ~isempty(qrs) % If there is no results file and we have something to put in one, create a file!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile([],[],[],[],[],qrs);
                elseif ~isfile % If there is no results file and we don't have something to put in one, don't create one yet - wait!
                    isfirst = 1;
                elseif isfile && ~isempty(qrs) % If there is a results file and we have something to put in it, put it in!
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                    % Note: If there is a results file and we don't have anything to put in it, there is nothing more to do
                end
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