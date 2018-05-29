function [hrt,hr,rrt,rr,ecgt,ecg,qrs] = runQRSDetection2(hObject,eventdata,handles)
    % Get signal data for data currently in window
    ecg = double(handles.sig);
    % Get rid of missing data
    ecg(ecg==-32768)=NaN;
    % Sampling frequency
    fs = handles.fs;
    % Get time vector for data currently in window
    ecgt = handles.utctime;
    % Convert to mV
    gain=400;
    if ~strcmp(handles.unitofmeasure,'mV')
        ecg=ecg/gain;
    end
%     THIS IS ONLY FOR UAB data
%     ecg = (ecg-3071)/1023;

    %Find indices of detected heartbeats
    tic
    qrs=qrsdetect(ecg,fs,ecgt);
    toc
    qrst=ecgt(qrs);

    plot(ecgt,ecg);
    hold on
    plot(ecgt(qrs),ecg(qrs),'*')

    %Form RR intervals
    nb=length(qrs);
    new=diff(qrs)>fs;
    j1=find(new);
    j1=[1;(j1+1)];
    j2=[(j1(2:end)-1);nb];
    rr=[];
    rrt=[];
    for k=1:length(j1)
        j=(j1(k):j2(k));
        if length(j)<2,continue,end    
        qq=qrst(j);
        rrt=[rrt;qq(2:end)];
        rr=[rr;diff(qq)];
    end

    % Compare with HR vital sign:
    dataindex = ismember(handles.alldatasetnames,'/VitalSigns/HR');
    % Find the vital sign indices that line up most closely with the start
    % and end times of the window which is currently showing waveform data
    [~,startindex] = min(abs(handles.vt-handles.windowstarttime));
    [~,endindex] = min(abs(handles.vt-handles.windowendtime));
    % Get the HR data that is present in the visible window
    hr = handles.vdata(startindex:endindex,dataindex);
    utctime = handles.vt(startindex:endindex);
    hrt = utc2local(utctime/1000);

    rr = 60000./rr;
    [rrt,~,~] = utc2local(rrt/1000);
    ylim([0 350])
end

