function [result,t_temp,tag,tagcol] = abd_tag_combiner(tagcolumnsa,tagcolumnsb,tagcolumnsd,tagsa,tagsb,tagsd,info)
result = [];
t_temp = [];

startcola = strcmp(tagcolumnsa.tagname,'Start');
stopcola = strcmp(tagcolumnsa.tagname,'Stop');

startcolb = strcmp(tagcolumnsb.tagname,'Start');
stopcolb = strcmp(tagcolumnsb.tagname,'Stop');

startcold = strcmp(tagcolumnsd.tagname,'Start');
stopcold = strcmp(tagcolumnsd.tagname,'Stop');

if isempty(tagsa.tagtable)||isempty(tagsb.tagtable)||isempty(tagsd.tagtable)
    tglobal = info.times+info.timezero;
    result = zeros(length(tglobal),1);
    tag = zeros(0,3); % want this instead of an empty array because this empty array will have a width dimension, which is important for indexing later
    tagcol = {'Start';'Stop';'Duration';'WtdApneaDur'};
    return
end

starta = tagsa.tagtable(:,startcola); %tA,i from Lee paper: time of beginning of apnea (when the (black) probability of apnea curve increases through 0.1)
stopa = tagsa.tagtable(:,stopcola); %tA,f from Lee paper: time of end of apnea (when the (black) probability of apnea curve decreases through 0.1)

startb = tagsb.tagtable(:,startcolb); %tB from Lee paper: time of Bradycardia (when the average heart rate reported by the monitor falls through 100 bpm)
stopb = tagsb.tagtable(:,stopcolb);

startd = tagsa.tagtable(:,startcold); %tD from Lee paper: time of Desaturation (when SpO2 falls through 80%)
stopd = tagsa.tagtable(:,stopcold);

% Cycle through each apnea event to determine whether it meets the
% definition for an AB, AD, or ABD event
AB = zeros(length(starta),1);
AD = zeros(length(starta),1);
for a=1:length(tagsa)
    TB = startb-starta(a); % TB from Lee paper: tB - tA,i = time interval from beginning of apnea to bradycardia
    TD = startd-starta(a); % TD from Lee paper: tD - tA,i = time interval from beginning of apnea to desaturation

    tauB = startb-stopa(a); % tauB from Lee paper: tB - tA,f = time interval from end of apnea to bradycardia (I believe the i subscript in the paper is a mistake and should be f)
    tauD = startd-stopa(a); % tauD from Lee paper: tD - tA,f = time interval from end of apnea to desaturation (I believe the i subscript in the paper is a mistake and should be f)
    
    % Rule for AB event: AB if TB>0 AND [TB<50s OR tauB<25s]
    AB(a) = sum(TB>0&(TB<50000|tauB<25000));
    % Rule for AD event: AD if TD>0 AND [TD<55s OR tauD<38s]
    AD(a) = sum(TD>0&(TD<55000|tauD<38000));
end
% If both of the conditions AB and AD hold, it is an ABD event.
ABD = AB&AD;

wadcol = strcmp(tagcolumnsa.tagname,'WtdApneaDur');
durcol = strcmp(tagcolumnsa.tagname,'Duration');
rearrangetags = tagsa.tagtable(:,[find(startcola),find(stopcola),find(durcol),find(wadcol)]);
tag = rearrangetags(ABD,:);
tagcol = {'Start' 'Stop' 'Duration' 'WtdApneaDur'}';