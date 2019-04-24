function [result,tglobalnew] = resultfromtags(tag,tagcol,tglobal,info)

startcol = strcmp(tagcol.tagname,'Start');
stopcol = strcmp(tagcol.tagname,'Stop');
n = size(tag,1);
starttime = min(tglobal);
stoptime = max(tglobal);
sampleperiod = info.sampleperiod/max([info.alldata(:).block]); % create the most fine-grained time array so that any resolution tags will be able to be detected.
tglobalnew = (starttime:sampleperiod:stoptime)';
if ~isempty(tag)
    [A,startindices] = ismember(tag(:,startcol),tglobalnew);
    if any(A==0)
        for j=1:n
            if A(j)==0
                [~,startindices(j)] = min(abs(tglobalnew - tag(j,startcol)));
            end
        end
    end
    [A,stopindices] = ismember(tag(:,stopcol),tglobalnew);
    if any(A==0)
        for j=1:n
            if A(j)==0
                [~,stopindices(j)] = min(abs(tglobalnew - tag(j,stopcol)));
            end
        end
    end
end
result = zeros(length(tglobalnew),1);
if ~isempty(tag)
    for i=1:length(startindices)
        result(startindices(i):stopindices(i))=1;
    end
end