function [result,t_temp,tag,tagcol] = abd(info,result_tags,result_tagcolumns,result_tagtitle,result_qrs,ECG)
% Set ECG to 0 to use Apnea-NoECG. Set ECG to 1 to use Apnea with all ECG leads.

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

% Get apnea results
if ECG == 0
    idx = findresultindex('/Results/Apnea-NoECG',4,result_tagtitle);
    if sum(idx)
        apneatags = result_tags(idx);
        apneatagcolumns = result_tagcolumns(idx);
    else
        % Run apnea algorithm
        [~,~,at,a] = apneadetector(info,0,result_qrs);
        apneatags(1).tagtable = at;
        apneatagcolumns(1).tagname = a;
    end
elseif ECG == 1
    idx = findresultindex('/Results/Apnea',3,result_tagtitle);
    if sum(idx)
        apneatags = result_tags(idx);
        apneatagcolumns = result_tagcolumns(idx);
    else
        % Run apnea algorithm
        [~,~,at,a] = apneadetector(info,[],result_qrs);
        apneatags(1).tagtable = at;
        apneatagcolumns(1).tagname = a;
    end
end

% Get brady results
idx = findresultindex('/Results/Brady<100',2,result_tagtitle);
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
idx = findresultindex('/Results/Desat<80',2,result_tagtitle);
if sum(idx)
    desattags = result_tags(idx);
    desattagcolumns = result_tagcolumns(idx);
else
    % Run desat algorithm
    [~,~,dt,d] = desatdetector(info,80,1,0);
    desattags(1).tagtable = dt;
    desattagcolumns(1).tagname = d;
end

% Find the ABD overlap using Hoshik Lee's rules from "A new algorithm for detecting central apnea in neonates," Hoshik Lee et al 2012 Physiol. Meas. 33 1
% if ~isempty(desattagcolumns(1).tagname) && ~isempty(bradytagcolumns(1).tagname) && ~isempty(apneatagcolumns(1).tagname)
if ~isempty(desattags.tagtable) && ~isempty(bradytags.tagtable) && ~isempty(apneatags.tagtable)
    [~,~,tag,tagcol] = abd_tag_combiner(apneatagcolumns,bradytagcolumns,desattagcolumns,apneatags,bradytags,desattags,info);
else
    tag = [];
    tagcol = [];
end

result = [];
t_temp = [];
end