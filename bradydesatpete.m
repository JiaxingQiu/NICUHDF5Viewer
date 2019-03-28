function [result,t_temp,tag,tagcol] = bradydesatpete(info,thresh,result_tags,result_tagcolumns,result_tagtitle)

if isempty(result_tagtitle)
    if ~isempty(info.resultfile)
        result_tags = load(info.resultfile,'result_tags');
        result_tagcolumns = load(info.resultfile,'result_tagcolumns');
        result_tagtitle = load(info.resultfile,'result_tagtitle');
    end
end

% Get brady results
if sum(strcmp(result_tagtitle(:,1),'/Results/Brady<100-Pete'))
    bradyindex = strcmp(result_tagtitle(:,1),'/Results/Brady<100-Pete');
    bradytags = result_tags(bradyindex);
    bradytagcolumns = result_tagcolumns(bradyindex);
else
    % Run brady algorithm
    [~,~,bradytags,bradytagcolumns] = bradydetector(info,99.99,4,4000);
end

% Get desat results
if sum(strcmp(result_tagtitle(:,1),'/Results/Desat<80-Pete'))
    desatindex = strcmp(result_tagtitle(:,1),'/Results/Desat<80-Pete');
    desattags = result_tags(desatindex);
    desattagcolumns = result_tagcolumns(desatindex);
else
    % Run desat algorithm
    [~,~,desattags,desattagcolumns] = desatdetector(info,79.99,10,10000);
end

% Find the brady desat overlap
[result,t_temp,tag,tagcol] = tagmerge(bradytagcolumns,desattagcolumns,bradytags,desattags,thresh,info);

end
