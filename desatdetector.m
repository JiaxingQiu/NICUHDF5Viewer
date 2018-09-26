function [results,vt,tag,tagname] = desatdetector(filename,vdata,vname,vt,threshold,pmin,tmin)

% [vdata,vname,vt,~]=gethdf5vital(filename);
if isempty(vdata)
    load(filename,'values','vlabel','vt','vuom')
    [vdata,vname,vt]=getWUSTLvital2(values,vt,vlabel);
end
if sum(contains(vname,'/VitalSigns/SPO2-%'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-%');
elseif sum(contains(vname,'/VitalSigns/SPO2-perc'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-perc');
elseif sum(contains(vname,'/VitalSigns/SPO2_pct'))
    dataindex = ismember(vname,'/VitalSigns/SPO2_pct');
elseif sum(contains(vname,'/VitalSigns/SPO2'))
    dataindex = ismember(vname,'/VitalSigns/SPO2');
elseif sum(contains(vname,'SPO2'))
    dataindex = ismember(vname,'SPO2');
elseif sum(contains(vname,'/VitalSigns/SpO2'))
    dataindex = ismember(vname,'/VitalSigns/SpO2');
else
    results = [];
    vt = [];
    tag = [];
    tagname = [];
    return
end
spo2data = vdata(:,dataindex);
spo2data(spo2data<=1) = nan;

period = median(diff(vt/1000));
fs = 1/period;

[tag,tagname]=threshtags(spo2data,vt,threshold,ceil(pmin*fs),tmin,1);

[~,startindices] = ismember(tag(:,1),vt);
[~,endindices] = ismember(tag(:,2),vt);
results = zeros(length(spo2data),1);
for i=1:length(startindices)
    results(startindices(i):endindices(i))=1;
end