function addtoresultsfile2(filename,name,result,time,tag,tagcol,qrsinput)
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
% tagcol:   the name of the tagtable columns

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

% Find the Result Filename
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
else
    resultfilename = strrep(filename,'.mat','_results.mat');
end

% Handle Timestamps that are not UTC (were originally seconds from event, now in datenum(duration) format)
isutc = strcmp(h5readatt(filename,'/','Timezone'),'UTC');
if ~isutc
    tag(:,3) = datenum(tag(:,3))*86400; % convert to seconds
end

% If the file does not already exist, create a file
if ~exist(resultfilename,'file')
    
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
    
%     if ~isempty(result) % Results and Tags
%         result_name{1,1} = name;
%         result_data(1).data = result;
%         result_data(1).time = time;
%         result_tags(1).tagtable = tag;
%         result_tagcolumns(1).tagname = tagname;
%         result_tagtitle{1,1} = name;
%         result_qrs = struct;
%     elseif ~isempty(tagname) % Tags Only
%         result_name = {};
%         result_data.data = [];
%         result_data.time = [];
%         result_tags(1).tagtable = tag;
%         result_tagcolumns(1).tagname = tagname;
%         result_tagtitle{1,1} = name;
%         result_qrs = struct;
%     else % QRS Detection
%         result_name = {};
%         result_data.data = [];
%         result_data.time = [];
%         result_tags.tagtable = [];
%         result_tagcolumns.tagname = [];
%         result_tagtitle = {};
%         result_qrs = struct;
%         result_qrs(qrsinput.lead).qrs = qrsinput;
%     end
else
    % check to see if results already contain this algorithm name
    load(resultfilename,'result_name','result_data','result_tags','result_tagcolumns','result_tagtitle');
    % Load qrs separately because old versions of the results files don't have it
    varinfo = who('-file',resultfilename);
    if ismember('result_qrs',varinfo)
        load(resultfilename,'result_qrs')
    else
        result_qrs = struct;
    end
    
    if ~isempty(tagcol)
        if any(strcmp(result_tagtitle,name))
            tagindex = find(strcmp(result_tagtitle, name));
        else
            tagindex = size(result_tagtitle,1)+1;
        end
    end
    
    if ~isempty(result)
        if any(strcmp(result_name,name))
            dataindex = find(strcmp(result_name, name));
        else
            dataindex = length(result_name)+1;
        end
    end
    
    if contains(name,'CustomTag')
        result_name{dataindex,1} = name;
        result_data(dataindex).data = result_data(dataindex).data|result;
        result_data(dataindex).time = time;
        result_tags(tagindex).tagtable = vertcat(result_tags(dataindex).tagtable,tag);
        result_tags(tagindex).tagtable = sortrows(result_tags(dataindex).tagtable);
        result_tagcolumns(tagindex).tagname = tagcol;
        result_tagtitle{tagindex,1} = name;
    else
        if exist('dataindex')
            result_name{dataindex,1} = name;
            result_data(dataindex).data = result;
            result_data(dataindex).time = time;
        end
        if exist('tagindex')
            result_tagtitle{tagindex,1} = name;
            result_tags(tagindex).tagtable = tag;
            result_tagcolumns(tagindex).tagname = tagcol;
        end
    end
    
    if ~isempty(qrsinput)
        result_qrs(qrsinput.lead).qrs = qrsinput;
    end
        
%     if ~isempty(tagcol)
%         if any(strcmp(result_tagtitle,tagcol))
%             dataindex = find(strcmp(result_name, name));
%             tagindex = find(strcmp(result_tagtitle, tagcol));
%             if contains(name,'CustomTag')
%                 result_data(dataindex).data = result_data(dataindex).data|result;
%                 result_tags(tagindex).tagtable = vertcat(result_tags(dataindex).tagtable,tag);
%                 result_tags(tagindex).tagtable = sortrows(result_tags(dataindex).tagtable);
%             else
%                 result_data(dataindex).data = result;
%                 result_data(dataindex).time = time;
%                 result_tags(tagindex).tagtable = tag;
%             end
%         else
%             dataindex = length(result_name)+1;
%             result_name{dataindex,1} = name;
%             result_tags(tagindex).tagtable = tag;
%             result_data(dataindex).data = result;
%             result_data(dataindex).time = time;
%         end
%         result_tagcolumns(tagindex).tagname = tagcol;
%         result_tagtitle{tagindex,1} = name;
%     else
%         if ~exist('result_qrs')
%             result_qrs = struct;
%         end
%         result_qrs(qrsinput.lead).qrs = qrsinput;
%     end
end
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','result_data','result_qrs');
