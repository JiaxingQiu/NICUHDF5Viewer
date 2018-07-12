function [results,vt,tag,tagname] = desatdetector(filename,threshold,pmin,tmin)

[vdata,vname,vt,~]=gethdf5vital(filename);
if isempty(vdata)
    load(filename,'values','vlabel','vt','vuom')
    [vdata,vname,vt]=getWUSTLvital2(values,vt,vlabel);
end
if sum(contains(vname,'/VitalSigns/SPO2-%'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-%');
elseif sum(contains(vname,'/VitalSigns/SPO2-perc'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-perc');
elseif sum(contains(vname,'/VitalSigns/SPO2'))
    dataindex = ismember(vname,'/VitalSigns/SPO2');
elseif sum(contains(vname,'SPO2'))
    dataindex = ismember(vname,'SPO2');
else
    results = [];
    vt = [];
    tag = [];
    tagname = [];
    return
end
spo2data = vdata(:,dataindex);

results = spo2data<=threshold;
[tag,tagname]=threshtags(spo2data,vt,threshold,pmin,tmin);