function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile(name,result,time,tag,tagcol,qrsinput)
    % Store Results Data
    if ~isempty(result)
        result_name{1,1} = name;
        result_data(1).data = result;
        result_data(1).time = time;
    else
        result_name = {};
        result_data.data = [];
        result_data.time = [];
    end

    % Store Tag Data
    if ~isempty(tagcol)
        result_tags(1).tagtable = tag;
        result_tagcolumns(1).tagname = tagcol;
        result_tagtitle{1,1} = name;
    else
        result_tags.tagtable = [];
        result_tagcolumns.tagname = [];
        result_tagtitle = {};
    end

    % Store QRS Data
    if ~isempty(qrsinput)
        result_qrs(qrsinput.lead).qrs = qrsinput;
    else
        result_qrs = struct;
    end
end