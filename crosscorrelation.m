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
if isempty(data1)
    return
end
[mydata1,~,~] = formatdata(data1,info,3,-1); % Load it in using global time stamps
% If the necessary data isn't available, return empty matrices & exit

% mydata1 = data1.x;
% vt1 = data1.t;

% Remove negative values
mydata1(mydata1<=1) = nan;

% Load in the var2 signal
[data2,~,info] = getfiledata(info,var2);
[mydata2,vt,xfs] = formatdata(data2,info,3,-1);

% If the necessary data isn't available, return empty matrices & exit
if isempty(data2)
    return
end

% Remove negative values
mydata2(mydata2<=1) = nan;

% Put the data in the format needed for Doug's script
vdata = [mydata1,mydata2]; % Put data in two columns
vt = vt/info.tunit; % put timestamps in seconds
% If vitals are every second, grab every 2 second data
if xfs==1
    vdata = vdata(1:2:end,:);
    vt = vt(1:2:end);
end

% The following code was extracted from vitalsumstats, written by Doug Lake:

% vdata - raw 2-second vital sign vdata
% vt - times of vital signs
% vname - vital sign names
% dw - calculation frequency in seconds
%      (default - every 10 minutes)
% w  - window for calculations in seconds
%      (default - last 10 minutes)
% xt - times of calculations

dt=2;
numLags=15;
dw=600;
w=[-600 0];

tmin=min(vt);
tmax=max(vt);

% Make 10 minute windows every 10 minutes
wmin=ceil(tmin/dw);
wmax=ceil(tmax/dw);
xt=dw*(wmin:wmax)';
[t1,t2]=findwindows(xt,w,vt);
nw=t2-t1+1;
j=nw>0;
xt=xt(j);
t1=t1(j);
t2=t2(j);
nt=length(xt);

c=NaN*ones(nt,4);
disp(nt)
for i=1:nt
    k=(t1(i):t2(i))';
    if isempty(k),continue,end
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
tagname=cell(5,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Value'; % This is Maximum cross correlation. It is labeled as "value" so that it plots the max xcorr in the viewer
tagname{4}='LagMax';
tagname{5}='MinCrossCorr'; % Minimum cross correlation
tagname{6}='LagMin';

vt=vt*info.tunit; % put timestamps back in UTC ms
tag=[vt(t1) vt(t2) c(:,1) c(:,2) c(:,3) c(:,4)];