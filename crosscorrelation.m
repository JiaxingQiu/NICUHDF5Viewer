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

% % Load in the var1 signal
% [data1,~,info] = getfiledata(info,var1);
% % If the necessary data isn't available, return empty matrices & exit
% if isempty(data1)
%     return
% end
% [data1,~,~] = formatdata(data1,info,3,1);
% mydata1 = data1.x;
% vt1 = data1.t;
% % Remove negative values
% mydata1(mydata1<=1) = nan;
% % Remove nans
% vt1(isnan(mydata1)) = [];
% mydata1(isnan(mydata1)) = [];
% %Round timestamps to every two seconds and downsample to every 2 seconds by
% %taking last value
% 
% dt=2000;
% vt1=dt*ceil(vt1/dt);
% 
% [vt1,ia] = unique(vt1,'last');
% mydata1 = mydata1(ia);
% 
% % Load in the var2 signal
% [data2,~,info] = getfiledata(info,var2);
% % If the necessary data isn't available, return empty matrices & exit
% if isempty(data2)
%     return
% end
% [data2,~,~] = formatdata(data2,info,3,1);
% mydata2 = data2.x;
% vt2 = data2.t;
% % Remove negative values
% mydata2(mydata2<=1) = nan;
% % Remove nans
% vt2(isnan(mydata2)) = [];
% mydata2(isnan(mydata2)) = [];
% 
% vt2=dt*ceil(vt2/dt);
% 
% [vt2,ia] = unique(vt2,'last');
% mydata2 = mydata2(ia);
% 
% % Keep only data that occurs at the same timestamps in both datasets
% [vt,vt1i,vt2i] = intersect(vt1,vt2,'sorted');
% 
% % Find all unique time points 
% if isempty(vt),return,end
% mydata1 = mydata1(vt1i);
% mydata2 = mydata2(vt2i);

% Put the data in the format needed for Doug's script
vname={var1,var2}';
data=getfiledata(info,vname);
[vdata,vt]=formatdata(data,info,3,0);
good=sum(~isnan(vdata),2)>0;
vt=vt(good);
nt=length(vt);
if nt==0,return,end
vdata=vdata(good,:);
%Downsample to every 2 secs
% dtms=2000;
% vt=dtms*ceil(vtms/dtms);
% [vt,ia]=unique(vt,'last');
% vdata=vdata(ia,:);
% put timestamps in seconds
vt=vt/1000;

% 
% [vt1,ia] = unique(vt1,'last');
% mydata1 = mydata1(ia);


% dt=2000;
% vt1=dt*ceil(vt1/dt);
% 
% [vt1,ia] = unique(vt1,'last');
% mydata1 = mydata1(ia);

% vdata = [mydata1,mydata2]; % Put data in two columns
% vt = vt/1000; % put timestamps in seconds
% nt=length(vt);

% The following code was extracted from vitalsumstats, written by Doug Lake:

% vdata - raw 2-second vital sign vdata
% vt - times of vital signs
% vname - vital sign names
% dw - calculation frequency in seconds
%      (default - every 10 minutes)
% w  - window for calculations in seconds
%      (default - last 10 minutes)
% xt - times of calculations

%Convert everything to seconds
%Find 10-minute windows stop times and assign each time to a window number

dw=600;
windowms=dw*1000;
win=[-dw 0];
wt=unique(dw*ceil(vt/dw));
[w1,w2]=findwindows(wt,win,vt);
j=find(w2>=w1);
w1=w1(j);
w2=w2(j);
wt=wt(j);
%[wt,~,w]=unique(dw*ceil(vt/dw));
nw=length(wt);

if nw==0,return,end

% w2=find(diff(w)>0);
% w1=[1;(w2+1)];
% w2=[w2;nt];

% This is the period that crosscorr2 will resample the data to
dt=2; 
numLags=15;
%nmin=200;
% dw=600;
% %w=[-600 0];
% windowms=dw*1000;
% wt=dw*unique(ceil(vt/dw));
% nw=length(wt);

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
np=zeros(nw,2);
for i=1:nw

%    k=find(vt>wt(i)-dw&vt<=wt(i));    
     k=(w1(i):w2(i))';
     if isempty(k),continue,end    
%     v=double(vdata(k,:));
%     tt=double(vt(k));    
%    v(v<=0)=NaN;
    x=vdata(k,:);    
    xt=vt(k);
    
    np(i,:)=sum(~isnan(x),1);
    if min(np(i,:))==0,continue,end
%    [xcf,lags]=xcorrstand(v,tt,numLags,dt);
    [xcf,lags]=crosscorr2(x,xt,numLags,dt);    
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
tagname{4}='Number points Signal 1';
tagname{5}='Number points Signal 2';
tagname{6}='Value'; % This is Maximum cross correlation. It is labeled as "value" so that it plots the max xcorr in the viewer
tagname{7}='LagMax';
tagname{8}='MinCrossCorr'; % Minimum cross correlation
tagname{9}='LagMin';

windowms=dw*1000;
wt=wt*1000; % put timestamps back to ms
dur=windowms*ones(nw,1);

tag=[wt-windowms wt dur np c];

% vt=vt*info.tunit; % put timestamps back in UTC ms
% tag=[vt(t1) vt(t2) c(:,1) c(:,2) c(:,3) c(:,4) vt(t2)-vt(t1)+median(diff(vt1))];
