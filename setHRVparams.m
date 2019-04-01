function HRVparams=setHRVparams(varargin)
%function HRVparams=setHRVparams(fs)
% inputs
%   fs:         sampling frequency
%   thres:      energy threshold of the detector
%               (default: 0.6) [arbitrary units]
%   ref_period: refractory period in sec between two R-peaks
%               (default: 0.250)
%   window:     size of the window in sec onto which to perform QRS detection
%               (defalt 15 seconds)
% 
%   OUTPUT:
%       HRVparams - struct of various settings for the hrv_toolbox analysis


%Find input variables
fs=NaN;
thres=NaN;
ref_period=NaN;
window=NaN;

nargin=length(varargin);

if nargin>0
    fs=varargin{1};
end
if nargin>1
    thres=varargin{2};
end
if nargin>2
    ref_period=varargin{3};
end
if nargin>3
    window=varargin{4};
end

%Default parameters
HRVparams.Fs = 250;
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
if ~isnan(thres)
    HRVparams.PeakDetect.THRES=thres;
end
if ~isnan(ref_period)
    HRVparams.PeakDetect.REF_PERIOD=REF_PERIOD;
end
if ~isnan(window)
    HRVparams.PeakDetect.windows=window;
end
