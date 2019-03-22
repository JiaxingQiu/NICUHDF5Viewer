function [name,data,tagtitles,tagcolumns,tags,result_qrs] = getresultsfile3(resultsfilename)
name = [];
data = [];
tagtitles = [];
tagcolumns = [];
tags = [];
result_qrs = [];
if isempty(resultsfilename)
    return
end

if exist(resultsfilename, 'file') == 2
    try
        name = load(resultsfilename,'result_name');
        name = name.result_name;
    end
    try
        data = load(resultsfilename,'result_data');
        data = data.result_data;
    end
    try
        tagtitles = load(resultsfilename,'result_tagtitle');
        tagtitles = tagtitles.result_tagtitle;
    end
    try
        tagcolumns = load(resultsfilename,'result_tagcolumns');
        tagcolumns = tagcolumns.result_tagcolumns;
    end
    try
        tags = load(resultsfilename,'result_tags');
        tags = tags.result_tags;
    end
    try
        result_qrs = load(resultsfilename,'result_qrs');
        result_qrs = result_qrs.result_qrs;
    end
else
    return
end