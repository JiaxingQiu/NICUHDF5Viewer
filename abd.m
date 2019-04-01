function [result,t_temp,tag,tagcol] = abd(info,thresh,result_tags,result_tagcolumns,result_tagtitle,result_qrs)

t_temp = info.times+info.timezero;
result = zeros(length(t_temp),1);
tag = [];
tagcol = {'Start';'Stop';'Duration'};

if isempty(result_tagtitle)
    if ~isempty(info.resultfile)
        result_tags = load(info.resultfile,'result_tags');
        result_tagcolumns = load(info.resultfile,'result_tagcolumns');
        result_tagtitle = load(info.resultfile,'result_tagtitle');
    end
end

% Get apnea results
if sum(strcmp(result_tagtitle(:,1),'/Results/Apnea-NoECG'))
    apneaindex = strcmp(result_tagtitle(:,1),'/Results/Apnea-NoECG');
    apneatags = result_tags(apneaindex);
    apneatagcolumns = result_tagcolumns(apneaindex);
else
    % Run apnea algorithm
    [~,~,apneatags,apneatagcolumns] = apneadetector(info,0,result_qrs);
end

if isempty(apneatags)
    return
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

if isempty(bradytags)
    return
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

if isempty(desattags)
    return
end

% Find the ABD overlap
[result,t_temp,tag,tagcol] = tripletagmerge(apneatagcolumns,bradytagcolumns,desattagcolumns,apneatags,bradytags,desattags,thresh,info);

end
