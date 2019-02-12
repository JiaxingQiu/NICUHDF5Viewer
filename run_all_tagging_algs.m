function run_all_tagging_algs(filename,vdata,vname,vt,wdata,wname,wt,algstorun)
nalgs = 21;
if isempty(algstorun)
    algstorun = ones(nalgs,1);
end

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
        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = runalg(filename,vdata,vname,vt,wdata,wname,wt,i,firstindex,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
    end
end

% Find the Result Filename
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
else
    resultfilename = strrep(filename,'.mat','_results.mat');
end

% Save the Results
msgbox('Saving the results','Tagging','modal');
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','result_data','result_qrs');

msgbox('Tagging Algorithms Complete','Tagging','modal');
end

function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = runalg(filename,vdata,vname,vt,wdata,wname,wt,algnum,firstindex,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs)
    isfirst = firstindex==algnum;
    algdispname = {...
        'QRS Detection: ECG I';...
        'QRS Detection: ECG II';...
        'QRS Detection: ECG III';...
        'CU Artifact';...
        'WUSTL Artifact';...
        'Brady Detection';...
        'Desat Detection';...
        'Apnea Detection with ECG Lead I';...
        'Apnea Detection with ECG Lead II';...
        'Apnea Detection with ECG Lead III';...
        'Apnea Detection with No ECG Lead';...
        'Periodic Breathing';...
        'Brady Detection Pete';...
        'Desat Detection Pete';...
        'Data Available: Pulse';...
        'Data Available: HR';...
        'Data Available: SPO2_pct';...
        'Data Available: Resp';...
        'Data Available: ECG I';...
        'Data Available: ECG II';...
        'Data Available: ECG III'};
    
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
                % QRS Detection with ECGI
                qrs = qrsdetector(filename,1,wdata,wname,wt);
            case 2
                % QRS Detection with ECGII
                qrs = qrsdetector(filename,2,wdata,wname,wt);
            case 3
                % QRS Detection with ECGIII
                qrs = qrsdetector(filename,3,wdata,wname,wt);
            case 4
                % Run and plot Columbia artifact removal, which works by comparing HR vs SPO2-R. Removes data which has a discrepancy between sensors.
                [result,t_temp,tag,tagcol] = cu_artifact_removal(filename,vdata,vname,vt,pmin,tmin);
            case 5
                % Run and plot WashU artifact removal, which works by removing low or missing SPO2-% data, then removing big jumps (of >3%)
                [result,t_temp,tag,tagcol] = wustl_artifact_removal(filename,50,vdata,vname,vt,pmin,tmin); % 50 is the threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
            case 6
                % Run a bradycardia detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagcol] = bradydetector(filename,vdata,vname,vt,99.99,pmin,tmin);
            case 7
                % Run a desaturation detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagcol] = desatdetector(filename,vdata,vname,vt,79.99,pmin,tmin);
            case 8 
                % Apnea detection algorithm using lead I
                [result,t_temp,tag,tagcol,qrs] = apneadetector(filename,1,wdata,wname,wt);
            case 9
                % Apnea detection algorithm using lead II
                [result,t_temp,tag,tagcol,qrs] = apneadetector(filename,2,wdata,wname,wt);
            case 10
                % Apnea detection algorithm using lead III
                [result,t_temp,tag,tagcol,qrs] = apneadetector(filename,3,wdata,wname,wt);
            case 11
                % Apnea detection algorithm using no EKG lead
                [result,t_temp,tag,tagcol] = apneadetector(filename,0,wdata,wname,wt);
            case 12
                % Mary Mohr's periodic breathing algorithm
                [result,t_temp,tag,tagcol] = periodicbreathing(filename);
            case 13
                % Pete's bradycardia detection algorithm: Bradys are <100 for ECG HR for at least 4 seconds. Joining rule for bradys is 4 seconds
                [result,t_temp,tag,tagcol] = bradydetector(filename,vdata,vname,vt,99.99,4,4000);
            case 14
                % Pete's Desat detection algorithm: <80% for at least 10 seconds if two of those events happen within 10 seconds of eachother, join them together as one event
                [result,t_temp,tag,tagcol] = desatdetector(filename,vdata,vname,vt,79.99,10,10000);
            case 15
                % Determine when a pulse signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'Pulse',1);
            case 16
                % Determine when a hr signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'HR',1);
            case 17
                % Determine when a spo2% signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'SPO2_pct',1);
            case 18
                % Determine when a resp signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'Resp',0);
            case 19
                % Determine when an ECGI signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'ECGI',0);
            case 20
                % Determine when an ECGII signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'ECGII',0);
            case 21
                % Determine when an ECGII signal exists
                [~,~,tag,tagcol] = dataavailable(filename,vdata,vname,vt,pmin,tmin,'ECGIII',0);

        end
        if exist('result')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,resultname{algnum-3},result,t_temp,tag,tagcol,[]);
                isfirst = 0;
            else
                if ~isempty(result)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(filename,resultname{algnum-3},result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs); % Must subtract 3 for resultname because qrs detection doesn't have a resultname
                end
            end
        elseif exist('tagcol') % For dataavailable results
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,algdispname{algnum},[],[],tag,tagcol,[]);
                isfirst = 0;
            else
                if ~isempty(tagcol)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(filename,algdispname{algnum},[],[],tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                end
            end
        end
        if exist('qrs')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,algdispname{algnum},[],[],[],[],qrs);
            else
                if ~isempty(qrs)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(filename,algdispname{algnum},[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                end
            end
        end
    catch
        msgbox(['Failure running algorithm ' num2str(algnum) ' of ' num2str(length(algdispname)) ': ' algdispname{algnum} '. Continuing running tagging algorithms.'],msgboxtitle,'modal');
        pause(1)
    end

end