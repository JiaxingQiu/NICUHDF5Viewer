function [qrs,t0]=qrsdetect(ecg,fs,t)

if ~exist('fs','var'),fs=240;end
if ~exist('t','var'),t=[];end
n=length(ecg);
if isempty(t)
    t=(1:n)/fs;
end
qrs=[];
good=~isnan(ecg);
g1=find(good,1);
g2=find(good,1,'last');
g=(g1:g2)';
if isempty(g),return,end
ecg=ecg(g);
good=good(g);
t=t(g);
if sum(~good)>0       
    ecg(~good)=interp1(t(good),ecg(good),t(~good));
end
ecg=double(ecg);
t0=t(1)-1/fs;
[qrs,sign,en_thres]=qrs_detect2(ecg,0.25,0.6,fs);
qrs=qrs(:);
