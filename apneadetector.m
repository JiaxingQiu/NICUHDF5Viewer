function [results,pt,tag,tagname] = apneadetector(filename,lead)
[wdata,wname,wt,~]=gethdf5wave(filename);
if sum(any(strcmp(wname,'/Waveforms/RR')))
    dataindex = strcmp(wname,'/Waveforms/RR');
else
    results = [];
    pt = [];
    tag = [];
    tagname = [];
    return
end
resp = wdata(:,dataindex);
respt = wt;
try
    CIfs = double(h5readatt(filename,wname{dataindex},'Sample Frequency (Hz)'));
catch
    CIfs = 1/(double(h5readatt(filename,wname{dataindex},'Sample Period (ms)'))/1000);
end


if lead == 1
    if sum(any(strcmp(wname,'/Waveforms/I')))
        dataindex = strcmp(wname,'/Waveforms/I');
    else
        results = [];
        pt = [];
        tag = [];
        tagname = [];
        return
    end
elseif lead == 2
    if sum(any(strcmp(wname,'/Waveforms/II')))
        dataindex = strcmp(wname,'/Waveforms/II');
    else
        results = [];
        pt = [];
        tag = [];
        tagname = [];
        return
    end
elseif lead == 3
    if sum(any(strcmp(wname,'/Waveforms/III')))
        dataindex = strcmp(wname,'/Waveforms/III');
    else
        results = [];
        pt = [];
        tag = [];
        tagname = [];
        return
    end
end
ecg = wdata(:,dataindex);
ecgt = wt;
% fs = 1000*1/median(diff(wt));

fs=240;
CIfs = 60;
% CIfs=60;
gain=1;%400;

addpath('Apnea')
[qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt/1000,gain,fs);
goodrespvals = ~isnan(resp);
resp = resp(goodrespvals);
respt = respt(goodrespvals);
[p,pt,pgood]=tombstone(resp,respt/1000,qt(qgood),qb(qgood),CIfs);
[tag,tagname,tag0]=wmtagevents(p,pgood,pt);
results = p;