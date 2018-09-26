function [results,pt,tag,tagname] = apneadetector(filename,lead,wdata,wname,wt)
if sum(any(strcmp(wname,'/Waveforms/RR')))
    dataindex = strcmp(wname,'/Waveforms/RR');
    varname = '/Waveforms/RR';
elseif sum(any(strcmp(wname,'/Waveforms/RESP')))
    dataindex = strcmp(wname,'/Waveforms/RESP');
    varname = '/Waveforms/RESP';
elseif sum(any(strcmp(wname,'/Waveforms/Resp')))
    dataindex = strcmp(wname,'/Waveforms/Resp');
    varname = '/Waveforms/Resp';
else
    results = [];
    pt = [];
    tag = [];
    tagname = [];
    return
end
% 
% resp = wdata(:,dataindex);
% respt = wt;

[resp,xt,fs,start,data,name,fac]=getwavedata(filename,varname);
respt = (start+xt/fs)*1000;
CIfs = fs;

% try
%     CIfs = double(h5readatt(filename,wname{dataindex},'Sample Frequency (Hz)'));
% catch
%     CIfs = 1/(double(h5readatt(filename,wname{dataindex},'Sample Period (ms)'))/1000);
% end


if lead == 1
    if sum(any(strcmp(wname,'/Waveforms/I')))
        dataindex = strcmp(wname,'/Waveforms/I');
        varname = '/Waveforms/I';
    elseif sum(any(strcmp(wname,'/Waveforms/CmpndECG(I)')))
        dataindex = strcmp(wname,'/Waveforms/CmpndECG(I)');
        varname = '/Waveforms/CmpndECG(I)';
    elseif sum(any(strcmp(wname,'/Waveforms/ECG')))
        dataindex = strcmp(wname,'/Waveforms/ECG');
        varname = '/Waveforms/ECG';
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
        varname = '/Waveforms/II';
    elseif sum(any(strcmp(wname,'/Waveforms/CmpndECG(II)')))
        dataindex = strcmp(wname,'/Waveforms/CmpndECG(II)');
        varname = '/Waveforms/CmpndECG(II)';
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
        varname = '/Waveforms/III';
    elseif sum(any(strcmp(wname,'/Waveforms/CmpndECG(III)')))
        dataindex = strcmp(wname,'/Waveforms/CmpndECG(III)');
        varname = '/Waveforms/CmpndECG(III)';
    else
        results = [];
        pt = [];
        tag = [];
        tagname = [];
        return
    end
end

[ecg,xt,fs,start,data,name,fac]=getwavedata(filename,varname);
ecgt = (start+xt/fs)*1000;

% ecg = wdata(:,dataindex);
% ecgt = wt;
% 
% fs=240;
% CIfs = 60;
gain=1;%400;

addpath('Apnea')
addpath('QRSDetection')
[qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt/1000,gain,fs);
goodrespvals = ~isnan(resp);
resp = resp(goodrespvals);
respt = respt(goodrespvals);
[p,pt,pgood]=tombstone(resp,respt/1000,qt(qgood),qb(qgood),CIfs);
if ~isempty(pgood)
    [tag,tagname,tag0]=wmtagevents(p,pgood,pt*1000);
else
    tag = [];
    tagname = [];
    tag0 = [];
end

% addpath('ApneaNew')
% % Initialize variables
% if ~exist('leadname','var')
%     leadname={'/Waveforms/I','/Waveforms/II','/Waveforms/III'}';
% end
% 
% if ~exist('respname','var')
%     respname='/Waveforms/RR';
% end
% 
% if ~exist('CWRU','var')
%     CWRU=false;
% end
% 
% if ~exist('dw','var')
%     dw=12*3600;
% end
% 
% % Get start and stop times for the signal
% start=0;
% try
%     start=h5readatt(filename,'/','Start Time');
%     start=double(start)/1000;    
% end
% fstart=utc2local(start);
% disp(datestr(fstart))
% 
% stop=0;
% try
%     stop=h5readatt(filename,'/','End Time');
%     stop=double(stop)/1000;    
% end
% fend=utc2local(stop);
% disp(datestr(fend))
% 
% dur=stop-start;
% if stop-start>dw
%     window=start+[0 dw];
%     dur=dw;
% else
%     window=[];
% end
% 
% %Get EKG and resp waveforms
% nlead=length(leadname);
% lead=1;
% %Find lead with most data in window
% if nlead>1
%     tdata=gethdf5dataapnea(filename,leadname,window,true);                
%     nt=zeros(nlead,1);
%     for i=1:nlead
%         nt(i)=length(tdata(i).t);
%     end
%     [~,lead]=max(nt);
% end
% ecgname=leadname{lead}; 
% [resp,respt,respfs]=getwavedata(filename,respname,window,1);
% [ecg,ecgt,ecgfs]=getwavedata(filename,ecgname,window);    
% 
% %Filter out high frequency noise in waveforms at CWRU
% if CWRU
%     [b,a]=butter(5,2*40/ecgfs,'low');
%     ecg=filtfilt(b,a,ecg);
% end
% 
% if CWRU
%     [b,a]=butter(5,2*5/respfs,'low');
%     resp=filtfilt(b,a,resp);    
%     n=length(resp);
%     resp=mean(reshape(resp,4,n/4));
%     respt=respt(4:4:n);
%     respfs=respfs/4;
% end
% 
% %Convert time stamps to relative to start time 0
% respt=respt-start;
% ecgt=ecgt-start;
% 
% 
% 
% 
% [qt,qb]=tombqrs(ecg,ecgt,ecgfs);
% goodrespvals = ~isnan(resp);
% resp = resp(goodrespvals);
% respt = respt(goodrespvals);
% [p,pt,pgood,psd]=tombstone(resp,respt/1000,respfs,qt,qb);
% [tag,tagname,tag0]=wmtagevents(p,pgood,pt);

results = p;