function [results,vt,tag,tagname] = call_hctsa(info,algname,var)

% Add algorithm folders to path
if ~isdeployed
    addpath([fileparts(which('call_hctsa.m')) '\hctsa'])
end

% Load in the var signal
[data,~,info] = getfiledata(info,var);
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data)
    return
end
mydata = data.x;
vt = data.t;

% Remove negative values
mydata(mydata<=1) = nan;

% Remove duplicate timestamps. Only keep the data value relating to the last
% copy of a given timestamp;
[vt,ia] = unique(vt,'last');
mydata = mydata(ia);

% % Get rid of missing data
% j=find(isnan(mydata));
% mydata(j)=[];
% vt(j)=[];
% if isempty(mydata),return,end

% 10 minute data indices
totalms = vt(end)-vt(1);
totalchunks = ceil(totalms/1000/60/10); % divide into 10 minute chunks
tsamp = median(diff(vt));
value = zeros(totalchunks,1);
np = zeros(totalchunks,1);
t1 = zeros(totalchunks,1);
t2 = zeros(totalchunks,1);
nansindata = zeros(totalchunks,1);
for c=1:totalchunks
    t1(c) = vt(1)+(c-1)*1000*60*10;
    t2ideal = vt(1)+c*1000*60*10-tsamp;
    [~,closestIndex] = min(abs(vt-t2ideal));
    t2(c) = vt(closestIndex);
    indicesinwindow = vt>=t1(c) & vt<=t2(c);
    
    % Get rid of missing data
    tenminofdata = mydata(indicesinwindow);
    j=find(isnan(tenminofdata));
    tenminofdata(j)=[];
    vt(j)=[];
    if isempty(tenminofdata),return,end
    
    switch algname
        case 'FC_Surprise'
            out = FC_Surprise(tenminofdata);
            value(c) = out.mean;
            nansindata(c) = length(j);
        case 'SB_MotifTwo'
%             out = SB_MotifTwo(mydata(indicesinwindow));
%             value(c) = out.uu;
    end
    np(c) = sum(indicesinwindow); % number of points
end

% Store means in the tags
tagname=cell(5,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Value';
tagname{6}='Nans in data';

dur = t2+tsamp-t1;

tag=[t1 t2+tsamp dur np value nansindata];

results = [];
vt = [];
