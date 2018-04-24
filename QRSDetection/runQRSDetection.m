function [hrt,hr,rrt,rr] = runQRSDetection(hdf5file,lead,sigstart,sigsamples)
    wdata=gethdf5wave(hdf5file,sigstart,sigsamples,lead);
    ecg=double(wdata.x);
    %Get rid of missing data
    ecg(ecg==-32768)=NaN;
    %Sampling frequency
    fs = wdata.fs;
    t=wdata.t;
    dt = median(diff(t)); % added this
    ecgt=blocktime(ecg,t,dt); % Changed this to dt
    %Convert to mV
    gain=400;
    ecg=ecg/gain;

    %Find indices of detected heartbeats
    tic
    qrs=qrsdetect(ecg,fs,ecgt);
    toc
    qrst=ecgt(qrs);

%     plot(ecgt,ecg);
%     hold on
%     plot(ecgt(qrs),ecg(qrs),'*')

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
        rr=[rr;1000*diff(qq)];
    end

    %Compare with HR vital sign
    [hr,~,hrt]=gethdf5vital(hdf5file,sigstart,sigsamples,'HR');
%     [hrt,~,~] = utc2local(double(hrt)/dt);
    rr = 60000./rr;
%     [rrt,~,~] = utc2local(double(rrt)/dt);
end

