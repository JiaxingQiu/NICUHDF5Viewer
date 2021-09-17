function [results,vt,tag,tagname] = crosscorrelation(info,var1,var2)
% INPUT:
% info:      from getfileinfo - if empty, it will go get it
% var1:      this can be any of the variables in the VariableNames.mat file (it should be a string)
% var2:      this can be any of the variables in the VariableNames.mat file (it should be a string)

% OUTPUT:
% results: empty array
% vt:      empty array
% tag:     tags ready to be saved in the results file
% tagname: tagnames ready to be saved in the results file

% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];

% Load in the var1 signal
[data1,~,info] = getfiledata(info,var1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data1)
    return
end
[data1,~,~] = formatdata(data1,info,3,1);
mydata1 = data1.x;
vt1 = data1.t;
% Remove negative values
mydata1(mydata1<=1) = nan;
% Remove nans
vt1(isnan(mydata1)) = [];
mydata1(isnan(mydata1)) = [];
%Round timestamps to every two seconds and downsample to every 2 seconds by
%taking last value

dt=2000;
vt1=dt*ceil(vt1/dt);

[vt1,ia] = unique(vt1,'last');
mydata1 = mydata1(ia);

% Load in the var2 signal
[data2,~,info] = getfiledata(info,var2);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data2)
    return
end
[data2,~,~] = formatdata(data2,info,3,1);
mydata2 = data2.x;
vt2 = data2.t;
% Remove negative values
mydata2(mydata2<=1) = nan;
% Remove nans
vt2(isnan(mydata2)) = [];
mydata2(isnan(mydata2)) = [];

vt2=dt*ceil(vt2/dt);

[vt2,ia] = unique(vt2,'last');
mydata2 = mydata2(ia);

% Keep only data that occurs at the same timestamps in both datasets
[vt,vt1i,vt2i] = intersect(vt1,vt2,'sorted');
if isempty(vt),return,end
mydata1 = mydata1(vt1i);
mydata2 = mydata2(vt2i);

% Put the data in the format needed for Doug's script
vdata = [mydata1,mydata2]; % Put data in two columns
vt = vt/1000; % put timestamps in seconds

% The following code was extracted from vitalsumstats, written by Doug Lake:

% vdata - raw 2-second vital sign vdata
% vt - times of vital signs
% vname - vital sign names
% dw - calculation frequency in seconds
%      (default - every 10 minutes)
% w  - window for calculations in seconds
%      (default - last 10 minutes)
% xt - times of calculations

dt=2; % This is the period that xcorrstand will resample the data to
numLags=15;
dw=600;
%w=[-600 0];
windowms=dw*1000;
wt=dw*unique(ceil(vt/dw));
nw=length(wt);
nmin=200;
% tmin=min(vt);
% tmax=max(vt);
% 
% % Make 10 minute windows every 10 minutes
% wmin=ceil(tmin/dw);
% wmax=ceil(tmax/dw);
% xt=dw*(wmin:wmax)';
% [t1,t2]=findwindows(xt,w,vt);
% nw=t2-t1+1;
% j=nw>0;
% xt=xt(j);
% t1=t1(j);
% t2=t2(j);
% nt=length(xt);

c=NaN*ones(nw,4);
np=zeros(nw,1);
for i=1:nw
    k=find(vt>wt(i)-dw&vt<=wt(i));    
%    k=(t1(i):t2(i))';
    if isempty(k),continue,end
    np(i)=length(k);
    if np(i)<nmin,continue,end
    v=double(vdata(k,:));
    tt=double(vt(k));    
    v(v<=0)=NaN;
    [xcf,lags]=xcorrstand(v,tt,numLags,dt);
    if sum(isnan(xcf))>0,continue,end
    [z,d]=max(xcf);
    c(i,1)=z; % maximum cross correlation
    c(i,2)=lags(d); % lag of max cross correlation
    [z,d]=min(xcf);
    c(i,3)=z; % minimum cross correlation
    c(i,4)=lags(d); % lag of min cross correlation
end

% Store Max C
tagname=cell(8,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Value'; % This is Maximum cross correlation. It is labeled as "value" so that it plots the max xcorr in the viewer
tagname{6}='LagMax';
tagname{7}='MinCrossCorr'; % Minimum cross correlation
tagname{8}='LagMin';

wt=wt*1000; % put timestamps back in UTC ms
dur=windowms*ones(nw,1);

tag=[wt-windowms wt dur np c];

% vt=vt*info.tunit; % put timestamps back in UTC ms
% tag=[vt(t1) vt(t2) c(:,1) c(:,2) c(:,3) c(:,4) vt(t2)-vt(t1)+median(diff(vt1))];
