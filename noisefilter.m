function [spo2,spo2good,hr,hrgood,t]=noisefilter(rawspo2,rawhr,ns)
%
% rawspo2   raw spo2 waveform
% rawhr     raw hr waveform
% ns        integer number of samples per second (default=2)

%
% spo2      sampled spo2 vital sign    
% spo2good  good spo2 points
% hr        sampled hr vital sign
% hrgood    good hr points
% t         time stsmps for vital signs

if ~exist('ns','var'),ns=2;end
    
% Hard code parameters
fs=200;

% Good data thresholds

dx=.5;
maxrange=15;
minvalue=5;

% Different parameters for HR
hrdx=1;
hrmaxrange=60;

% At least half of points in window close to sampled value

numthresh=fs/2;

[spo2,spo2num,spo2max,spo2min,t]=downsamplestats(rawspo2,fs,ns,dx);
spo2(spo2>100)=100;
spo2good=isolatedbad(spo2,spo2num>=numthresh,hrdx);
spo2range=spo2max-spo2min;
spo2good=spo2good&spo2min>minvalue;
spo2good=spo2good&spo2range<maxrange;

[hr,hrnum,hrmax,hrmin]=downsamplestats(rawhr,fs,ns,hrdx);
hr(hr>250)=250;
hrgood=isolatedbad(hr,hrnum>=numthresh,dx);
hrrange=hrmax-hrmin;
hrgood=hrgood&hrmin>minvalue;
hrgood=hrgood&hrrange<hrmaxrange;

%Round off vital signs to integers
% hr=round(hr);
% spo2=round(spo2);
