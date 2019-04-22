function name=fixedname(name)
% signame can be any one of the following:
%    'Pulse'
%    'HR'
%    'SPO2_pct'
%    'Resp'
%    'ECGI'
%    'ECGII'
%    'ECGIII'

name0=name;
% Get the list of all possible variable strings that go with the desired signame
if ~isdeployed
    load('X:\Amanda\NICUHDF5Viewer\VariableNames','VariableNames')
else
    loadfilename = which(fullfile('VariableNames.mat'));
    load(loadfilename,'VariableNames')
end
vname=fieldnames(VariableNames);
for i=1:length(vname)
    v=getfield(VariableNames,vname{i});
    for j=1:length(v)
        k=strmatch(v(j).Name,name0,'exact');
        if ~isempty(k)
            name{k}=vname{i};
            break
        end
    end
end
