function [results,vt,tag,tagname] = hourlymetric(info,var,metric)
% Compute hourly metrics and store them in tags

% INPUT:
% info:      from getfileinfo - if empty, it will go get it
% var:       this can be any of the variables in the VariableNames.mat file (it should be a string)
% metric:    a string stating what type of metric (ex. mean, std, skewness, kurtosis) we want to run on the data

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

% Load in the var signal
[data,~,info] = getfiledata(info,var);
[data,~,~] = formatdata(data,info,3,1);
% If the necessary data isn't available, return empty matrices & exit
if isempty(data)
    return
end
mydata = data.x;
vt = data.t;

% Remove negative HR values
mydata(mydata<=1) = nan;

% Remove duplicate timestamps. Only keep the data value relating to the last
% copy of a given timestamp;
[vt,ia] = unique(vt,'last');
mydata = mydata(ia);

% Get rid of missing data
j=find(isnan(mydata));
mydata(j)=[];
vt(j)=[];
if isempty(mydata),return,end

% Hourly data indices
totalms = vt(end)-vt(1);
totalhours = ceil(totalms/1000/60/60);
tsamp = median(diff(vt));
value = zeros(totalhours,1);
np = zeros(totalhours,1);
t1 = zeros(totalhours,1);
t2 = zeros(totalhours,1);
for h=1:totalhours
    t1(h) = vt(1)+(h-1)*1000*60*60;
    t2ideal = vt(1)+h*1000*60*60-tsamp;
    [~,closestIndex] = min(abs(vt-t2ideal));
    t2(h) = vt(closestIndex);
    indicesinwindow = vt>=t1(h) & vt<=t2(h);
    switch metric
        case 'mean'
            value(h) = mean(mydata(indicesinwindow));
        case 'std'
            value(h) = std(mydata(indicesinwindow));
        case 'skewness'
            value(h) = skewness(mydata(indicesinwindow));
        case 'kurtosis'
            value(h) = kurtosis(mydata(indicesinwindow));
    end
    np(h) = sum(indicesinwindow); % number of points
end

% Store means in the tags
tagname=cell(5,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Value';

dur = t2+tsamp-t1;

tag=[t1 t2+tsamp dur np value];

results = [];
vt = [];