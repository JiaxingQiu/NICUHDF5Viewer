%Waveform sampling frequencies
fs=200;
CIfs=fs;
gain=1;
%Number of samples per beat for heart rate filter 
ns=30;
%Number of apnea probabilities per second
ps=4;

%datdir='X:\PreVent\CWRU\8003\';
datdir='X:\PreVent\CWRU\1000\';
D=dir([datdir,'*.dat']);
facfile=[datdir,'ScalingFactors.txt'];
fac=load(facfile);

nf=length(D);
datfile=cell(nf,1);
for i=1:nf
    datfile{i}=[datdir,D(i).name];
end

apnea=[];

for f=1:nf

if f>1,continue,end

file=datfile{f};
apnea(f,:).file=file;
fid=fopen(file);
[data,name,fac]=getcwrudata(file,fac);
disp(name);

% data=[];
% if fid>0
%     tic
%     data=fread(fid,[4 inf],'*int16','ieee-be');
%     toc
%     fclose(fid);
% end
% 
% data=data';

% spo2=round(downsample(100*(fac(2)*double(data(:,3))+fac(1)),fs));
% hr=round(downsample(250*(fac(2)*double(data(:,4))+fac(1)),fs));
spo2=data(5).x;
hr=data(6).x;

vt=(1:length(hr))';

apnea(f).hr=hr;
apnea(f).hrt=vt;
apnea(f).spo2=spo2;
apnea(f).spo2t=vt;

%Filter out high frequency noise in waveforms

ecg=fac(2)*double(data(1).x)+fac(1);
%ecg=fac(2)*double(data(:,1))+fac(1);
[b,a]=butter(5,2*40/fs,'low');
ecg=filtfilt(b,a,ecg);
n=length(ecg);
gain=1;
t=(1:n)'/fs;
[b,a]=butter(5,2*5/fs,'low');

%resp=filtfilt(b,a,double(data(:,2)));
resp=filtfilt(b,a,double(data(2).x));

tic
[qt,qb,qgood,x,xt]=tombqrs(ecg,t,gain,fs);
[p,pt,pgood]=tombstone(resp,t,qt(qgood),qb(qgood),CIfs);
[tag,tagname,tag0]=wmtagevents(p,pgood,pt);
toc

disp(sum(tag(:,3)>10))

apnea(f).pt=pt;
apnea(f).p=p;
apnea(f).pgood=pgood;
apnea(f).tag=tag;
apnea(f).tagname=tagname;

end

save alldatapnea apnea fac fs CIfs ns ps
