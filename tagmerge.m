function [result,tglobal,tag,tagcol] = tagmerge(tagcolumnsa,tagcolumnsb,tagsa,tagsb,thresh,info)

% Find tag overlap within threshold of thresh ms
startcola = strcmp(tagcolumnsa.tagname,'Start');
stopcola = strcmp(tagcolumnsa.tagname,'Stop');

startcolb = strcmp(tagcolumnsb.tagname,'Start');
stopcolb = strcmp(tagcolumnsb.tagname,'Stop');

if isempty(tagsa.tagtable)||isempty(tagsb.tagtable)
    tglobal = info.times+info.timezero;
    result = zeros(length(tglobal),1);
    tag = zeros(0,3); % want this instead of an empty array because this empty array will have a width dimension, which is important for indexing later
    tagcol = {'Start';'Stop';'Duration'};
    return
end

starta = tagsa.tagtable(:,startcola);
stopa = tagsa.tagtable(:,stopcola);

startb = tagsb.tagtable(:,startcolb);
stopb = tagsb.tagtable(:,stopcolb);

startstart = starta-startb';
startstop = starta-stopb';
stopstart = stopa-startb';

binstartstart = abs(startstart)<=thresh;
binstartstop = abs(startstop)<=thresh;
binstopstart = abs(stopstart)<=thresh;

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
if ~isempty(starts)
    tag(:,1) = starts;
    computedstops = maxstop(~isnan(maxstop));
    tag(:,2) = computedstops(startorder);
    tag(:,3) = tag(:,2)-tag(:,1); %Duration of tag in ms
else
    tag = zeros(0,3);  % Amanda added this recently - may need to check this
end

% Store tag time points in a binary array
tglobal = info.times+info.timezero;
tagcoltemp.tagname = tagcol;
result = resultfromtags(tag,tagcoltemp,tglobal,info);