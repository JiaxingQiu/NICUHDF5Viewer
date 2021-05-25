function [qt,qecg,qs]=getqrs(ecg,ecgt,fs,tunit)
%function [qt,qecg,qs]=getqrs(ecg,ecgt,fs)
%
% ecg       ECG waveform
% ecgt      timestamp for EKG in milliseconds
% fs        sampling freauency (default=125Hz)
% tunit     number of time units per second (default=1=>s)
%
% qt        times of detected heartbeats
% qecg      value of ecg at detected heartbeat
% qs        segment of data used to run qrs detector

if ~exist('tunit','var'),tunit=1;end
if ~exist('fs','var'),fs=125;end

%Set default HRV parameters for toolbox
HRVparams=setHRVparams;

%Set ECG frequency
HRVparams.Fs=fs;

%Hard code parameters for qrs detection
window=15;
thres=.6;
ref_period=.2;
HRVparams.PeakDetect.windows=window;
HRVparams.PeakDetect.THRES=thres;
HRVparams.PeakDetect.REF_PERIOD=ref_period;

%Get rid of NaN segments of 1 second or more (fs samples)
fmin=1*fs;

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
sub=nf>=fmin;
j1=j1(sub);
j2=j2(sub);
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
    if length(good)~=length(ecgt)
        msg = 'Data is a different length than the timestamps. \Data length is %g. Time length is %g. \nThis is an error we have seen in hdf5 files converted from stp where the stp file contains thousands of improperly repeated timestamps. \nThe algorithm SHOULD fail here and not return a result. \nThis stp waveform is corrupt and should not be used to generate results. \nThis is appropriate. No correction is needed. \nHowever, if this error occurs with a file that was not converted from stp, please investigate further.';
        error(msg,length(ecg),length(ecgt))
    end
    ecgt=ecgt(good);
end

%Fill in other missing data with nearest value
ecg=fillmissing(ecg,'nearest');

%Break up into segments without any gaps

%Gap threshold to be consecutive samples
gap=1.5*tunit/fs;

n=length(ecg);
j1=1;
j2=n;
new=find(diff(ecgt)>=gap);
if ~isempty(new)
    j1=[j1;(new+1)];    
    j2=[new;j2];
end

%Process each segment
ns=length(j1);
qt=[];
qecg=[];
qs=[];
for i=1:ns
    j=(j1(i):j2(i))';    
    x=double(ecg(j));
    t=ecgt(j);    
%    [q,sign,en_thres]=qrs_detect2(x,0.2,0.6,fs);
    q=run_qrsdet_by_seg(x,HRVparams);   
    q=q(:);
    nq=length(q);
    qt=[qt;t(q)];
    qecg=[qecg;x(q)];    
    qs=[qs;i*ones(nq,1)];
%     disp([i length(x) nq])
end
