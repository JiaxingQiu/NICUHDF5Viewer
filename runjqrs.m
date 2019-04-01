function [qt,qecg,qs,s,ecg,ecgt]=runjqrs(ecg,ecgt,fs,tunit,gap)
%function [qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt,gain,fs)
%
% ecg ECG waveform
% ecgt timestamp for EKG
% gain gain for EKG (default 400)
% fs sampling freauency for interpolated signal (default=240Hz)
%
% qt        times of detected heartbeats
% qecg      value of ecg at detected heartbeat
% x interpolated EKG signal
% xt timestamps for interpolated EKG signal

if ~exist('tunit','var'),tunit=1000;end
if ~exist('gap','var'),gap=1000;end

HRVparams.Fs=fs;
window = HRVparams.PeakDetect.windows;
thres = HRVparams.PeakDetect.THRES;
ecgType = HRVparams.PeakDetect.ecgType;

q3=run_qrsdet_by_seg(ecg,HRVparams);
%Get rid of NaN segments of 1 second or more
fmin=1;
bad=find(isnan(ecg));
nb=length(bad);
j1=1;
j2=nb;
j=find(diff(bad)>1);
if ~isempty(j)
    j1=[j1;(j+1)];    
    j2=[j;j2];
end
%Number of NaN points in each segment
nf=j2-j1+1;
sub=nf>=fs*fmin;
j1=j1(sub);
j2=j2(sub);
disp(length(j1));
n=length(ecg);
%Get rid of NaN segments
if ~isempty(j1)
    good=true(n,1);
    for i=1:length(j1)
        j=j1(i):j2(i);
        k=bad(j);
        good(k)=0;
    end
    ecg=ecg(good);
    ecgt=ecgt(good);
end

%Fill in other missing data with nearest value
ecg=fillmissing(ecg,'nearest');

%Break up into segments without gaps
n=length(ecg);
j1=1;
j2=n;
new=find(diff(ecgt)>=gap);
if ~isempty(new)
    j1=[j1;(new+1)];    
    j2=[new;j2];
end
nmin=10*fs;
sub=j2-j1+1>=nmin;
j1=j1(sub);
j2=j2(sub);

%Further break up into segments of no more than a half hour

% smax=1800*fs;
% 
% disp([j1 j2])
% k1=j1;
% k2=j2;
% j1=[];
% j2=[];
% for i=1:length(k1)
%     j1=[j1;k1(i)];
%     ss=k2(i)-k1(i)+1;
%     nn=ceil(ss/smax);      
%     dd=round(ss/nn);    
%     for k=1:(nn-1)
%         kk=k1(i)+k*dd;
%         j2=[j2;kk];
%         j1=[j1;kk+1];
%     end
%     j2=[j2;k2(i)];
% end
% disp([j1 j2])        

%Process each segment
ns=length(j1);
qt=[];
qecg=[];
qs=[];
s=zeros(n,1);
for i=1:ns
    j=(j1(i):j2(i))';
    x=ecg(j);
    t=ecgt(j);
    s(j)=i;
    disp([i min(t) max(t) length(x)])    
    tic
    [q,sign,en_thres]=qrs_detect2(x,0.2,0.6,fs);
    q=q(:);
    nq=length(q);
    qt=[qt;t(q)];
    qecg=[qecg;x(q)];    
    qs=[qs;i*ones(nq,1)];
    toc
    disp([i nq])
end

dq=60*tunit;
k=find(diff(qt)>dq);
for i=1:length(k)
    ss=ns+i;
    j=find(ecgt>qt(k(i))&ecgt<qt(k(i)+1));
    x=ecg(j);
    t=ecgt(j);
    s(j)=ss;
    disp([i min(t) max(t) length(x)])    
    tic
    [q,sign,en_thres]=qrs_detect2(x,0.2,0.6,fs);
    q=q(:);
    nq=length(q);
    qt=[qt;t(q)];
    qecg=[qecg;x(q)];    
    qs=[qs;ss*ones(nq,1)];
    toc
    disp([ss nq])
end
[qt,j]=sort(qt);
qecg=qecg(j);
qs=qs(q);

