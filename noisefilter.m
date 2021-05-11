function [spo2,spo2good,hr,hrgood,t]=noisefilter(rawspo2,rawhr,ns)
%
% rawspo2   raw spo2 waveform
% rawhr     raw hr waveform
% ns    number of samples per second

%
% spo2      sampled spo2 vital sign    
% spo2good  good spo2 points
% hr        sampled hr vital sign
% hrgood    good hr points
% t         time stsmps for vital signs

if ~exist('ns','var'),ns=1;end

% Hard code parameters
fs=200;
dx=.5;
skip=fs/ns;

N=length(rawspo2);

t=(skip:skip:N)'/fs;

% Good data thresholds

spo2maxrange=15;
hrmaxrange=60;
minvalue=5;

% At least half of points in window close to sampled value

numthresh=fs*ns/2;

[spo2,spo2num,spo2max,spo2min]=downsamplestats(rawspo2,fs,ns,dx);
spo2(spo2>100)=100;
spo2good=isolatedbad(spo2,spo2num>=numthresh,dx);
spo2range=spo2max-spo2min;
spo2good=spo2good&spo2min>minvalue;
spo2good=spo2good&spo2range<spo2maxrange;

[hr,hrnum,hrmax,hrmin]=downsamplestats(rawhr,fs,ns,dx);
hr(hr>250)=250;
hrgood=isolatedbad(hr,hrnum>=numthresh,dx);
hrrange=hrmax-hrmin;
hrgood=hrgood&hrmin>minvalue;
hrgood=hrgood&hrrange<hrmaxrange;
