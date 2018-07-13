function [results,vt,tag,tagname] = bradydetector(filename,threshold,pmin,tmin)

[vdata,vname,vt,~]=gethdf5vital(filename);
if isempty(vdata)
    load(filename,'values','vlabel','vt','vuom')
    [vdata,vname,vt]=getWUSTLvital2(values,vt,vlabel);
end
% if sum(contains(vname,'/VitalSigns/SPO2-R'))
%     dataindex = ismember(vname,'/VitalSigns/SPO2-R');
% elseif sum(contains(vname,'/VitalSigns/PULSE'))
%     dataindex = ismember(vname,'/VitalSigns/PULSE');
% end
% spo2rdata = vdata(:,dataindex);
if sum(contains(vname,'/VitalSigns/HR'))
    dataindex = ismember(vname,'/VitalSigns/HR');
elseif sum(contains(vname,'HR'))
    dataindex = ismember(vname,'HR');
elseif sum(contains(vname,'/VitalSigns/PR'))
    dataindex = ismember(vname,'/VitalSigns/PR');
end
hrdata = vdata(:,dataindex);

results = hrdata<=threshold;
[tag,tagname]=threshtags(hrdata,vt,threshold,pmin,tmin);