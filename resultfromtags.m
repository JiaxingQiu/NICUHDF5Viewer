function [result] = resultfromtags(tag,tagcol,tglobal)

startcol = strcmp(tagcol.tagname,'Start');
stopcol = strcmp(tagcol.tagname,'Stop');

[~,startindices] = ismember(round(tag(:,startcol),-3),round(tglobal,-3)); % round to the nearest second
[~,stopindices] = ismember(round(tag(:,stopcol),-3),round(tglobal,-3));
result = zeros(length(tglobal),1);
for i=1:length(startindices)
    result(startindices(i):stopindices(i))=1;
end