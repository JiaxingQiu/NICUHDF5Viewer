function fixedname=findfixedname(name)
% signame can be any one of the following:
%    'Pulse'
%    'HR'
%    'SPO2_pct'
%    'Resp'
%    'ECGI'
%    'ECGII'
%    'ECGIII'

% Get the list of all possible variable strings that go with the desired signame
load('X:\Amanda\NICUHDF5Viewer\VariableNames','VariableNames')
vname=fieldnames(VariableNames);
fixedname=name;
for i=1:length(vname)
    v=getfield(VariableNames,vname{i});
    for j=1:length(v)
        k=strmatch(v(j).Name,name,'exact');
        if ~isempty(k)
            fixedname{k}=vname{i};
            break
        end
    end
end



