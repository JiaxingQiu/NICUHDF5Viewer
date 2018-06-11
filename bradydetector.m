function [results,vt,tag,tagname] = bradydetector(filename,threshold,pmin,tmin)

[vdata,vname,vt,~]=gethdf5vital(filename);
% if sum(contains(vname,'/VitalSigns/SPO2-R'))
%     dataindex = ismember(vname,'/VitalSigns/SPO2-R');
% elseif sum(contains(vname,'/VitalSigns/PULSE'))
%     dataindex = ismember(vname,'/VitalSigns/PULSE');
% end
% spo2rdata = vdata(:,dataindex);
dataindex = ismember(vname,'/VitalSigns/HR');
hrdata = vdata(:,dataindex);

results = hrdata<=threshold;
[tag,tagname]=threshtags(hrdata,vt,threshold,pmin,tmin);