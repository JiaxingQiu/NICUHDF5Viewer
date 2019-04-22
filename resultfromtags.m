function [result,tglobalnew] = resultfromtags(tag,tagcol,tglobal,info)

startcol = strcmp(tagcol.tagname,'Start');
stopcol = strcmp(tagcol.tagname,'Stop');
n = size(tag,1);
% startindices = zeros(n,1);
% stopindices = zeros(n,1);
starttime = min(tglobal);
stoptime = max(tglobal);
sampleperiod = info.sampleperiod/max([info.alldata(:).block]); % create the most fine-grained time array so that any resolution tags will be able to be detected.
tglobalnew = (starttime:sampleperiod:stoptime)';

[A,startindices] = ismember(tag(:,startcol),tglobalnew);
if any(A==0)
    for j=1:n
        [~,startindices(j)] = min(abs(tglobalnew - tag(j,startcol)));
    end
end
[A,stopindices] = ismember(tag(:,stopcol),tglobalnew);
if any(A==0)
    for j=1:n
        [~,stopindices(j)] = min(abs(tglobalnew - tag(j,stopcol)));
    end
end
result = zeros(length(tglobalnew),1);
for i=1:length(startindices)
    result(startindices(i):stopindices(i))=1;
end