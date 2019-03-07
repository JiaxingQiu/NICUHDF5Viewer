function [data,name]=dat2data(file,name)
%[name,data,Attributes,info]=dat2hdf5(datfile,hdf5file)
%
%datfile        .dat file to read
%
% data          structure with signal data, timestamps and attributes
% name          name of each signal datset name
%[data,name,Attributes,rawdata]=getcwrudata(file,fac)
%
% file          input .dat file
% fac           scaling factors or name of file with factors
%
% data          structure with signal data, timestamps and attributes
% name          name of each signal datset name
% Attributes    root attributes for HDF5 file including ID and fac
% rawdata       matrix with raw data from file

if ~exist('name','var'),name=cell(0,1);end

data=[];
if isstr(name),name={name};end
    
%Find scaling factors
[pathstr,root]=fileparts(file);
facfile=fullfile(pathstr,'ScalingFactors.txt');
if ~isempty(dir(facfile))
    fac=load(facfile);
else
    fac=[];
end

%Hard code dat file names
dname={'/Waveforms/ECG','/Waveforms/RESP','/Waveforms/SPO2','/Waveforms/HR','/VitalSigns/SPO2','/VitalSigns/HR'}';

%Get requested names
%Otherwise, find which requested dataset groups exist
if isempty(name)
    name=dname;
    v=(1:length(name))';
else
    v=[];
    for i=1:length(name)
        j=strmatch(name{i},dname);
        v=[v;j];
    end
    name=dname(v);
end

nv=length(v);

%Hard code frequency
fs=200;

%Get raw data and start date from file
[rawdata,start]=getdatdata(file);
rawdata=double(rawdata);
%Find sequence of data assumed consecutive
[nr,nx]=size(rawdata);
nt=floor(nr/fs);
nr=nt*fs;
rawdata=rawdata(1:nr,:);

%Time in seconds
t=(1:nt)';
stop=start+nt/86400;
%Time in seconds from midnight
if ~isnan(start)
    t0=86400*(start-floor(start));
    t=t0+t;
end

%Scaling factor
if length(fac)>1
    rawdata=fac(2)*rawdata+fac(1);
end

%Extra hard-coded scaling factors for oversampled vital sign waveforms
rawdata(:,3)=100*rawdata(:,3);
rawdata(:,4)=250*rawdata(:,4);

% Convert to days/1000 because the surrounding code is horrible - my
% greatest apologies
t = t/86400; % Convert seconds to days
t = t/1000; % Because everything gets multiplied by 1000

for i=1:nv
    data(i,:).name=name{i};
    j=v(i);
    if j<=nx
        data(i).x=rawdata(:,j);
        data(i).fs=fs;
    else        
        data(i).x=downsample(rawdata(:,j-2),fs);
        data(i).fs=1;
    end
    data(i).t=t;    
end

%Filter out high frequency noise in ECG waveform
% [b,a]=butter(5,2*40/fs,'low');
% ecg=filtfilt(b,a,ecg);

%Filter out high frequency noise in RESP waveform
% [b,a]=butter(5,2*5/fs,'low');
% resp=filtfilt(b,a,double(rawdata(:,2)));

%Find SD for each second and identify low amplitude ECG outliers
% amp=log(std(reshape(ecg(1:(fs*nt)),fs,nt))');
% u=mean(amp(amp>-Inf));
% s=std(amp(amp>-Inf));
% amplow=u-3*s;
% %Mark low amplitude RESP as missing
% respgood=amp>=amplow;
% low=find(~respgood);
% nodata=-32768;
% for i=1:length(low)
%     j=fs*(low(i)-1)+(1:fs);
%     resp(j)=nodata;
% end

%Find SPO2 and HR outliers
% hrgood=hr>40;
% uhr=mean(hr(hrgood));
% shr=std(hr(hrgood));
% Thr=min(80,uhr-4*shr);
% hrgood=hrgood&hr>Thr;

% spo2good=spo2>40;
% uspo2=mean(spo2(spo2good));
% sspo2=std(spo2(spo2good));
% Tspo2=min(60,uspo2-4*sspo2);
% spo2good=spo2good&spo2>Tspo2;
% 
% %Time unit in milliseconds
% tunit=1000;
% T=tunit;
% for i=1:nv
%     data(i).t=int64(tunit*data(i).t);              
%     data(i).tunit=tunit;
%     data(i).T=T;    
% end

end

function [rawdata,start,id]=getdatdata(file)
%function [rawdata,start,id]=getdatdata(file)
%
% file = input .dat file
%
% rawdata = matrix with raw signal data
% start - start time in Matlab format (from file name)
% id - patient id (from file name)

[pathstr,root]=fileparts(file);

rawdata=[];

fid=fopen(file);
if fid>0
    rawdata=fread(fid,[4 inf],'int16','ieee-be')';
    fclose(fid);
end
%Get start date and id from filename
id=NaN;
start=NaN;

nr=length(root);
j=findstr('_',root);
if isempty(j)
    str=root;
else
    j1=j(1);
    str=root(1:(j1-1));    
end
try
    id=sscanf(str,'%d');
end
if length(j)>1
    str=root((j1+1):end);
    try
        start=datenum(str,'mmddyyyy_HHMMSS');
    end
end

end
