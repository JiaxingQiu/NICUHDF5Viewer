function [results,vt,tag,tagname] = desatdetector(filename,threshold,pmin,tmin)

[vdata,vname,vt,~]=gethdf5vital(filename);
if sum(contains(vname,'/VitalSigns/SPO2-%'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-%');
elseif sum(contains(vname,'/VitalSigns/SPO2-perc'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-perc');
elseif sum(contains(vname,'/VitalSigns/SPO2'))
    dataindex = ismember(vname,'/VitalSigns/SPO2');
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