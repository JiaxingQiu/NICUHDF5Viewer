function [tagtitles,tagcolumns,tags,result_qrs] = getresultsfile3(resultsfilename)
if isempty(resultsfilename)
    tagtitles = [];
    tagcolumns = [];
    tags = [];
    result_qrs = [];
    return
end

if exist(resultsfilename, 'file') == 2
    try
        tagtitles = load(resultsfilename,'result_tagtitle');
        tagtitles = tagtitles.result_tagtitle;
    catch
        tagtitles = [];
    end
    try
        tagcolumns = load(resultsfilename,'result_tagcolumns');
        tagcolumns = tagcolumns.result_tagcolumns;
    catch
        tagcolumns = [];
    end
    try
        tags = load(resultsfilename,'result_tags');
        tags = tags.result_tags;
    catch
        tags = [];
    end
    try
        result_qrs = load(resultsfilename,'result_qrs');
        result_qrs = result_qrs.result_qrs;
    catch
        result_qrs = [];
    end
else
    tagtitles = [];
    tagcolumns = [];
    tags = [];
    result_qrs = [];
end