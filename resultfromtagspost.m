function [result_binary,tglobalnew] = resultfromtagspost(result_tags,result_tagcolumns,fs,info)
maxalgnum = length(result_tags);

for a=1:maxalgnum
    tag = result_tags(a).tagtable;
    tagcol = result_tagcolumns(a);

    startcol = strcmp(tagcol.tagname,'Start');
    stopcol = strcmp(tagcol.tagname,'Stop');
    n = size(tag,1);
    starttime = info.start;
    stoptime = info.stop;
    tglobalnew = (starttime:round(1/fs*1000):stoptime)';
    if ~exist('result_binary')
        result_binary = zeros(maxalgnum,length(tglobalnew));
    end
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
    result_binary(a,:) = result;
    disp(['Completed binary generation for algorithm ' num2str(a) ' of ' num2str(maxalgnum)])
end
