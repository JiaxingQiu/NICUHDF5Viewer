function [data,name,time,tagtitles,tagcolumns,tags] = getresultsfile(fullfilename)
resultsfilename = [erase(fullfilename,".hdf5") '_results.mat'];
if exist(resultsfilename, 'file') == 2
    load(resultsfilename,'result_*');
    data = result_vital_data;
    name = result_vital_name;
    time = result_vital_time;
    tagtitles = result_tagtitle;
    tagcolumns = result_tagcolumns;
    tags = result_tags;
else
    data = [];
    name = [];
    time = [];
    tagtitles = [];
    tagcolumns = [];
    tags = [];
end