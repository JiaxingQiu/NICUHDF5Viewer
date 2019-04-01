function q=qrsbysegment(ecg,fs,window,ref_period,thres)
% this function is used to run the QRS detector for each window window (non overlapping)
% this is needed because in the case of big artefacts at the begining of
% the record (i.e. where the P&T threshold is computed) it can make the detection fail.
%
% inputs
%   ecg:        ecg signal
%   fs:         sampling frequency
%   window:     size of the window onto which to perform QRS detection (in seconds)
%   thres:      energy threshold of the detector (default: 0.6) 
%               [arbitrary units]
%   ref_period: refractory period in sec between two R-peaks (default: 0.250)
% 
% output
%   QRS:        QRS location in nb samples (ms)

%set NaNs to zero
j=find(isnan(ecg));
ecg(j)=0;

%Find input variables
fs=NaN;
window=NaN;
thres=NaN;
ecgType=NaN;
nargin=length(varargin);

if nargin>0
    fs=varargin{1};
end
if nargin>1
    window=varargin{2};
end
if nargin>2
    thres=varargin{3};
end
if nargin>3
    ecgType=varargin{4};
end

%Default parameters
HRVparams.Fs = 125;
HRVparams.PeakDetect.REF_PERIOD = 0.250;   % Default: 0.25 (should be 0.15 for FECG), refractory period in sec between two R-peaks
HRVparams.PeakDetect.THRES = .6;           % Default: 0.6, Energy threshold of the detector 
HRVparams.PeakDetect.fid_vec = [];         % Default: [], If some subsegments should not be used for finding the optimal 
                                           % threshold of the P&T then input the indices of the corresponding points here
HRVparams.PeakDetect.SIGN_FORCE = [];      % Default: [], Force sign of peaks (positive value/negative value)
HRVparams.PeakDetect.debug = 0;            % Default: 0
HRVparams.PeakDetect.ecgType = 'MECG';     % Default : MECG, options (adult MECG) or featl ECG (fECG) 
HRVparams.PeakDetect.windows = 15;         % Befautl: 15,(in seconds) size of the window onto which to perform QRS detection

if ~isnan(fs)
    HRVparams.Fs=fs;
end
if ~isnan(window)
    HRVparams.PeakDetect.windows=window;
end
if ~isnan(thres)
    HRVparams.PeakDetect.THRES=thres;
end
if ~isnan(ecgType)
    HRVparams.PeakDetect.ecgType=ecgType;
end

ecg=double(ecg);
q=run_qrsdet_by_seg(ecg,HRVparams);
