function [result,t_temp,tag,tagcol] = bradydesat(info,thresh,result_tags,result_tagcolumns,result_tagtitle)

if isempty(result_tagtitle)
    if ~isempty(info.resultfile)
        result_tags = load(info.resultfile,'result_tags');
        if isfield(result_tags,'result_tags')
            result_tags = result_tags.result_tags;
        end
        result_tagcolumns = load(info.resultfile,'result_tagcolumns');
        if isfield(result_tagcolumns,'result_tagcolumns')
            result_tagcolumns = result_tagcolumns.result_tagcolumns;
        end
        result_tagtitle = load(info.resultfile,'result_tagtitle');
        if isfield(result_tagtitle,'result_tagtitle')
            result_tagtitle = result_tagtitle.result_tagtitle;
        end
    end
end

% Get brady results
idx = findresultindex('/Results/Brady<100',3,result_tagtitle);
if sum(idx)
    bradytags = result_tags(idx);
    bradytagcolumns = result_tagcolumns(idx);
else
    % Run brady algorithm
    [~,~,bt,b] = bradydetector(info,100,1,0);
    bradytags(1).tagtable = bt;
    bradytagcolumns(1).tagname = b;
end

% Get desat results
idx = findresultindex('/Results/Desat<80',3,result_tagtitle);
if sum(idx)
    desattags = result_tags(idx);
    desattagcolumns = result_tagcolumns(idx);
else
    % Run desat algorithm
    [~,~,dt,d] = desatdetector(info,80,1,0, 1, 1);
    desattags(1).tagtable = dt;
    desattagcolumns(1).tagname = d;
end

% Find the brady desat overlap
if ~isempty(desattagcolumns(1).tagname) && ~isempty(bradytagcolumns(1).tagname)
    [result,t_temp,tag,tagcol] = tagmerge(bradytagcolumns,desattagcolumns,bradytags,desattags,thresh,info);
else
    tag = [];
    tagcol = [];
end

result = [];
t_temp = [];

end