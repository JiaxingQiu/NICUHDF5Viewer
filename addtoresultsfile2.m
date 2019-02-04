function addtoresultsfile2(filename,name,result,time,tag,tagname)
% This saves results in a .mat file alongside the original hdf5 file. The
% results file is named [inputfilename]_results.mat. If the results file
% already contains an identical tagname, those corresponding prior tags are
% overwritten. If not, the tag data is appended to the existing results
% data.

% INPUT: 
% filename: the input file name with .hdf5 extension
% name:     the name of algorithm in the format '/Results/AlgorithmHere'
% result:   the time series output from the algorithm
% time:     the time vector that corresponds to result
% tag:      the tagtable for that algorithm
% tagname:  the name of the tagtable columns

% OUTPUT:
% The output [inputfilename]_results.mat file includes the following:
% result_name: a cell array of the algorithm names in the format '/Results/AlgorithmHere'
% result_data: a struct containing the time series result data and corresponding time stamps
% result_tags: a struct containing tagtables for each of the algorithms
% result_tagcolumns: a struct containing the column labels for each of the tagtables located in result_tags
% result_tagtitle: a cell array of the algorithm names in the format '/Results/AlgorithmHere'
% 
%  NOTE: result_tagtitle and result_name will be the same as long as each
%   algorithm has the capability of outputting tags and time series output.
%   If an algorithm has one but not the other, you will need to index by 
%   the correct one of these labels. (And check that downstream code is
%   pulling from the correct place (_name vs _tagtitle).
%


if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
else
    resultfilename = strrep(filename,'.mat','_results.mat');
end
if ~exist(resultfilename,'file')
    result_name{1,1} = name;
    result_data(1).data = result;
    result_data(1).time = time;
    result_tags(1).tagtable = tag;
    result_tagcolumns(1).tagname = tagname;
    result_tagtitle{1,1} = name;
else
    % check to see if results already contain this name
    load(resultfilename,'result_name','result_data','result_tags','result_tagcolumns','result_tagtitle');
    if any(strcmp(result_name,name))
        index = find(strcmp(result_name, name));
%             index = find(contains(result_vital_name,vname));
        if contains(name,'CustomTag')
            result_data(index).data = result_data(index).data|result;
            result_tags(index).tagtable = vertcat(result_tags(index).tagtable,tag);
            result_tags(index).tagtable = sortrows(result_tags(index).tagtable);
        else
            result_data(index).data = result;
            result_data(index).time = time;
            result_tags(index).tagtable = tag;
        end
    else
        index = length(result_name)+1;
        result_name{index,1} = name;
        result_tags(index).tagtable = tag;
        result_data(index).data = result;
        result_data(index).time = time;
    end
    result_tagcolumns(index).tagname = tagname;
    result_tagtitle{index,1} = name;
end
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','result_data');
