function [result,t_temp,tag,tagcol] = tagmerge(tagcolumnsa,tagcolumnsb,tagsa,tagsb,thresh,info)

% Find tag overlap within threshold of thresh ms
startcola = strcmp(tagcolumnsa.tagname,'Start');
stopcola = strcmp(tagcolumnsa.tagname,'Stop');

startcolb = strcmp(tagcolumnsb.tagname,'Start');
stopcolb = strcmp(tagcolumnsb.tagname,'Stop');

starta = tagsa.tagtable(:,startcola);
stopa = tagsa.tagtable(:,stopcola);

startb = tagsb.tagtable(:,startcolb);
stopb = tagsb.tagtable(:,stopcolb);

if isempty(starta)||isempty(startb)
    result = [];
    t_temp = [];
    tag = [];
    tagcol = [];
    return
end

startstart = starta-startb';
startstop = starta-stopb';
stopstart = stopa-startb';

binstartstart = abs(startstart)<thresh;
binstartstop = abs(startstop)<thresh;
binstopstart = abs(stopstart)<thresh;

overlap1 = startstart<=0&stopstart>=0;
overlap2 = startstart>=0&startstop<=0;

allsets = binstartstart|binstartstop|binstopstart|overlap1|overlap2;

size1 = size(allsets,1);
size2 = size(allsets,2);
minstart = nan*ones(size1,size2);
maxstop = nan*ones(size1,size2);
for a = 1:size1
    for b = 1:size2
        if allsets(a,b)==1
            minstart(a,b) = min(starta(a),startb(b));
            maxstop(a,b) = max(stopa(a),stopb(b));
            if a-1>0
                if allsets(a-1,b)==1
                    minstart(a,b) = min(minstart(a,b),minstart(a-1,b));
                    maxstop(a,b) = max(maxstop(a,b),maxstop(a-1,b));
                    minstart(a-1,b) = nan;
                    maxstop(a-1,b) = nan;
                end
            end
            if b-1>0
                if allsets(a,b-1)==1
                    minstart(a,b) = min(minstart(a,b),minstart(a,b-1));
                    maxstop(a,b) = max(maxstop(a,b),maxstop(a,b-1));
                    minstart(a,b-1) = nan;
                    maxstop(a,b-1) = nan;
                end
            end
        end
    end
end

% Create Tags
tagcol = {'Start';'Stop';'Duration'};
computedstarts = minstart(~isnan(minstart));
[starts,startorder] = sort(computedstarts);
tag(:,1) = starts;
computedstops = maxstop(~isnan(maxstop));
tag(:,2) = computedstops(startorder);
tag(:,3) = tag(:,2)-tag(:,1); %Duration of tag in ms

% Store tag time points in a binary array
t_temp = info.times+info.timezero;
[~,startindices] = ismember(tag(:,1),t_temp);
[~,endindices] = ismember(tag(:,2),t_temp);
result = zeros(length(t_temp),1);
for i=1:length(startindices)
    result(startindices(i):endindices(i))=1;
end