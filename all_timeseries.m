function [results,vt,tag,tagname] = all_timeseries(info,algname,var)
% Initialize output variables in case the necessary data isn't available
results = [];
vt = [];
tag = [];
tagname = [];

% Add algorithm folders to path
if ~isdeployed
    addpath([fileparts(which('call_hctsa.m')) '\hctsa'])
end

% Load in the var signal (will be HR or SPO2_pct)
[data,~,info] = getfiledata(info,var);
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data),return,end
mydata = data.x;
vt = data.t;

% Remove negative values
mydata(mydata<=1) = nan;

% Create a dataset that has no nans in it
j=find(isnan(mydata));
mydata(j)=[];
vt(j)=[];
if isempty(mydata),return,end

% Remove duplicate timestamps. Only keep the data value relating to the last
% copy of a given timestamp;

%Round timestamps to every two seconds and downsample to every 2 seconds by
%taking last value

dt=2000;
vt=dt*ceil(vt/dt);

[vt,ia] = unique(vt,'last');
mydata = mydata(ia);

% if median(diff(vt))<2000
%     vt = vt(2:2:end);
%     mydata = mydata(2:2:end);
% end

% Create a dataset that has no nans in it
% mydata_nonans = mydata;
% vt_nonans = vt;
% j=find(isnan(mydata));
% mydata_nonans(j)=[];
% vt_nonans(j)=[];
% if isempty(mydata_nonans),return,end

%Find 10-minute windows stop times

windowms=10*60*1000;
nmin=200;
wt=windowms*unique(ceil(vt/windowms));
nw=length(wt);
np=zeros(nw,1);
value=NaN*ones(nw,1);
for c=1:nw
    j=find(vt>wt(c)-windowms&vt<=wt(c));
    x=mydata(j);
    x(isnan(x))=[];
    np(c)=length(x);
    if np(c)<200,continue,end
    
    try
        switch algname
            case 'FC_Surprise'
                out = FC_Surprise(x);
                value(c) = out.mean;
            case 'SB_MotifTwo'
                out = SB_MotifTwo(x,'diff');
                value(c) = out.uu;
            case 'PH_Walker'
                out = PH_Walker(x,'momentum',2);
                value(c) = out.sw_stdrat;
            case 'EX_MovingThreshold'
                out = EX_MovingThreshold(x,0.25,0.1);
                value(c) = out.meanq;
            case 'DN_cv'
                out = DN_cv(x,3);
                value(c) = out;
            case 'DN_Cumulants'
                out = DN_Cumulants(x,'skew2');
                value(c) = out;
            case 'DN_Quantile'
                out = DN_Quantile(x,0.99);
                value(c) = out;
            case 'SB_TransitionMatrix_tau1'
                out = SB_TransitionMatrix(x,'quantile',2,1);
                value(c) = out.T3;
            case 'SB_TransitionMatrix_tau2'
                out = SB_TransitionMatrix(x,'quantile',2,2);
                value(c) = out.mineig;
            case 'SB_TransitionMatrix_tau3'
                out = SB_TransitionMatrix(x,'quantile',2,3);
                value(c) = out.stdeigcov;
            case 'MF_arfit'
                out = MF_arfit(x);
                value(c) = out.sbc_7;
            case 'SY_StdNthDer'
                out = SY_StdNthDer(x,17);
                value(c) = out;
            case 'DN_RemovePoints'
                out = DN_RemovePoints(x,'min',0.2);
                value(c) = out.mean;
            case 'SB_BinaryStats'
                out = SB_BinaryStats(x,'iqr');
                value(c) = out.pstretch1;
            case 'SB_MotifThree_quantile'
                out = SB_MotifThree(x,'quantile');
                value(c) = out.hhhh;
            case 'SB_MotifThree_diffquant'
                out = SB_MotifThree(x,'diffquant');
                value(c) = out.hhhh;
            case 'ST_LocalExtrema_SPO2'
                out = ST_LocalExtrema(x,'n',100);
                value(c) = out.minabsmin;
            case 'ST_LocalExtrema_HR'
                out = ST_LocalExtrema(x,'n',100);
                value(c) = out.minabsmin;
            case 'CO_tc3_HR'
                out = CO_tc3(x,1);
                value(c) = out.denom;
            case 'CO_tc3_SPO2'
                out = CO_tc3(x,1);
                value(c) = out.denom;
            case 'CO_AutoCorr'
                out = CO_AutoCorr(x,4,'TimeDomainStat');
                value(c) = out;
            case 'mean'
                value(c) = mean(x);
            case 'std'
                value(c) = std(x);
            case 'skewness'
                value(c) = skewness(x);
            case 'kurtosis'
                value(c) = kurtosis(x);
        end
    catch
        value(c) = nan;
    end
end

% Store means in the tags
tagname=cell(4,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Value';

dur=windowms*ones(nw,1);

tag=[wt-windowms wt dur np value];

results = [];
vt = [];
    
% % 10 minute data chunking
% totalms = vt_nonans(end)-vt_nonans(1);
% totalchunks = ceil(totalms/1000/60/10); % Find total number of 10 minute chunks
% tsamp = median(diff(vt)); % use vt here instead of vt_nonans on purpose to know what the real sampling frequency is
% value = ones(totalchunks,1)*nan;
% np = zeros(totalchunks,1);
% t1 = zeros(totalchunks,1);
% t2 = zeros(totalchunks,1);
% for c=1:totalchunks
%     % Find the start and end times of the chunk (If there are nans at the beginning of the file, we don't want to use that data)
%     t1(c) = vt_nonans(1)+(c-1)*1000*60*10; % ms
%     t2ideal = vt_nonans(1)+c*1000*60*10-tsamp;
%     
%     % Index back into the full dataset (nans included) to grab our ten minutes of data for our chunk
%     [~,closestIndex] = min(abs(vt-t2ideal));
%     t2(c) = vt(closestIndex);
%     indicesinwindow = vt>=t1(c) & vt<=t2(c);
%     tenminoftimestamps = vt(indicesinwindow);
%     tenminofdata = mydata(indicesinwindow);
%     
%     % If less than one minute's worth of data points are available in this chunk, don't run algorithm. Just return value(c) as nan.
%     if sum(~isnan(tenminofdata))<30,continue,end
%     
%     % Fill in nans using sample and hold (but don't fill in nans for DN algorithms since they deal with the distribution and not the order)
%     if ~strcmp(algname(1:2),'DN')
%         tenminofdata = fillmissing(tenminofdata,'previous');
%     end
%     
%     % Check for gaps in timestamps (i.e. actual missing timestamps)
%     % If there are missing timestamps, fill in the gaps with sample and hold (but don't do this for DN algorithms)
%     expectedsamples = (t2(c)-t1(c))/1000/2+1; % Number of samples expected in the time window
%     if length(tenminofdata)~=expectedsamples  && ~strcmp(algname(1:2),'DN') %&& length(tenminofdata)~=expectedsamples-1 % length of expectedsamples is accurate within a value of 1
%         tenminofdata = interp1(tenminoftimestamps,tenminofdata,(tenminoftimestamps(1):tsamp:tenminoftimestamps(end))','previous');
%     end
%     
%     % Then drop any leading nans at the beginning of the chunk of data
%     if ~strcmp(algname(1:2),'DN')
%         tenminofdata = tenminofdata(~isnan(tenminofdata));
%     end
%     
%     % Run the HCTSA algorithm
%     try
%         switch algname
%             case 'FC_Surprise'
%                 out = FC_Surprise(tenminofdata);
%                 value(c) = out.mean;
%             case 'SB_MotifTwo'
%                 out = SB_MotifTwo(tenminofdata,'diff');
%                 value(c) = out.uu;
%             case 'PH_Walker'
%                 out = PH_Walker(tenminofdata,'momentum',2);
%                 value(c) = out.sw_stdrat;
%             case 'EX_MovingThreshold'
%                 out = EX_MovingThreshold(tenminofdata,0.25,0.1);
%                 value(c) = out.meanq;
%             case 'DN_cv'
%                 out = DN_cv(tenminofdata,3);
%                 value(c) = out;
%             case 'DN_Cumulants'
%                 out = DN_Cumulants(tenminofdata,'skew2');
%                 value(c) = out;
%             case 'DN_Quantile'
%                 out = DN_Quantile(tenminofdata,0.99);
%                 value(c) = out;
%             case 'SB_TransitionMatrix_tau1'
%                 out = SB_TransitionMatrix(tenminofdata,'quantile',2,1);
%                 value(c) = out.T3;
%             case 'SB_TransitionMatrix_tau2'
%                 out = SB_TransitionMatrix(tenminofdata,'quantile',2,2);
%                 value(c) = out.mineig;
%             case 'SB_TransitionMatrix_tau3'
%                 out = SB_TransitionMatrix(tenminofdata,'quantile',2,3);
%                 value(c) = out.stdeigcov;
%             case 'MF_arfit'
%                 out = MF_arfit(tenminofdata);
%                 value(c) = out.sbc_7;
%             case 'SY_StdNthDer'
%                 out = SY_StdNthDer(tenminofdata,17);
%                 value(c) = out;
%             case 'DN_RemovePoints'
%                 out = DN_RemovePoints(tenminofdata,'min',0.2);
%                 value(c) = out.mean;
%             case 'SB_BinaryStats'
%                 out = SB_BinaryStats(tenminofdata,'iqr');
%                 value(c) = out.pstretch1;
%             case 'SB_MotifThree_quantile'
%                 out = SB_MotifThree(tenminofdata,'quantile');
%                 value(c) = out.hhhh;
%             case 'SB_MotifThree_diffquant'
%                 out = SB_MotifThree(tenminofdata,'diffquant');
%                 value(c) = out.hhhh;
%             case 'ST_LocalExtrema_SPO2'
%                 out = ST_LocalExtrema(tenminofdata,'n',100);
%                 value(c) = out.minabsmin;
%             case 'ST_LocalExtrema_HR'
%                 out = ST_LocalExtrema(tenminofdata,'n',100);
%                 value(c) = out.minabsmin;
%             case 'CO_tc3_HR'
%                 out = CO_tc3(tenminofdata,1);
%                 value(c) = out.denom;
%             case 'CO_tc3_SPO2'
%                 out = CO_tc3(tenminofdata,1);
%                 value(c) = out.denom;
%             case 'CO_AutoCorr'
%                 out = CO_AutoCorr(tenminofdata,4,'TimeDomainStat');
%                 value(c) = out;
%         end
%     catch
%         value(c) = nan;
%     end
%     np(c) = sum(indicesinwindow); % number of points
% end
% 
% % Store means in the tags
% tagname=cell(5,1);
% tagname{1}='Start';
% tagname{2}='Stop';
% tagname{3}='Duration';
% tagname{4}='Number points';
% tagname{5}='Value';
% 
% dur = t2+tsamp-t1;
% 
% tag=[t1 t2+tsamp dur np value];
% 
% results = [];
% vt = [];
