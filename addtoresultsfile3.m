function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(name,result,time,tag,tagcol,qrsinput,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs)
% This saves results in a .mat file alongside the original hdf5 file. The
% results file is named [inputfilename]_results.mat. If the results file
% already contains an identical tagname, those corresponding prior tags are
% overwritten. If not, the tag data is appended to the existing results
% data.

% INPUT: 
% filename:  the input file name with .hdf5 extension
% name:      the name of algorithm in the format '/Results/AlgorithmHere'
% result:    the time series output from the algorithm
% time:      the time vector that corresponds to result
% tag:       the tagtable for that algorithm
% tagcol:    the name of the tagtable columns
% qrsinput:  the qrs detection results

% OUTPUT:
% result_name:       a cell array of the algorithm names in the format '/Results/AlgorithmHere'
% result_data:       a struct containing the time series result data and corresponding time stamps
% result_tags:       a struct containing tagtables for each of the algorithms
% result_tagcolumns: a struct containing the column labels for each of the tagtables located in result_tags
% result_tagtitle:   a cell array of the algorithm names in the format '/Results/AlgorithmHere'
% result_qrs:        the qrs detection results stored totally separately

%  NOTE: result_tagtitle and result_name will be the same as long as each
%   algorithm has the capability of outputting tags and time series output.
%   If an algorithm has one but not the other, you will need to index by 
%   the correct one of these labels. (And check that downstream code is
%   pulling from the correct place (_name vs _tagtitle).

% Handle Timestamps that are not UTC (were originally seconds from event, now in double(datenum(duration)) format)
% isutc = strcmp(h5readatt(filename,'/','Timezone'),'UTC');
% if ~isutc && ~isempty(tag)
% 	tag(:,3) = datenum(tag(:,3))*86400; % convert to seconds
% end

% If the file does not already exist, create a file
if isempty(result_name)
    
    % Store Results Data
    if ~isempty(time)
        result_name = name;
        result_data(1).data = result;
        result_data(1).time = time;
    elseif ~exist('time')
        result_name = {};
        result_data.data = [];
        result_data.time = [];
    end
    
    % Store Tag Data
    if ~isempty(tagcol)
        result_tags(1).tagtable = tag;
        result_tagcolumns(1).tagname = tagcol;
        result_tagtitle = name;
        result_name = name;
        result_data(1).data = result;
        result_data(1).time = time;
    elseif ~exist('result_tags')
        result_tags.tagtable = [];
        result_tagcolumns.tagname = [];
        result_tagtitle = {};
    end
    
    % Store QRS Data
    if ~isempty(qrsinput)
        result_qrs(qrsinput.lead).qrs = qrsinput;
    elseif ~exist('result_qrs')
    	result_qrs = struct;
    end
    
else
    if size(name,2)==2 % if this is a name/version pairing, just grab the name. Otherwise, keep the whole name
        tagname = name(1);
    else
        tagname = name;
    end
    if ~isempty(tagcol)
        if isempty(result_tagtitle)
            tagindex = 1;
        elseif sum(contains(result_tagtitle(:,1),tagname)) % any(strcmp(result_tagtitle,name))
            tagindex = find(strcmp(result_tagtitle(:,1), tagname));
            if isempty(tagindex)
                tagindex = size(result_tagtitle,1)+1;
            end
        else
            tagindex = size(result_tagtitle,1)+1;
        end
        if sum(contains(result_name(:,1),tagname)) %any(strcmp(result_name,name))
            dataindex = find(strcmp(result_name(:,1), tagname));
            if isempty(dataindex)
                dataindex = size(result_name,1)+1;
            end
        else
            dataindex = size(result_name,1)+1;
        end
    end
    
    
    if size(result_tagtitle,2)==1 % if this is an old results file which does not contain a version number, add in a 1 for the version number
        oldversioncells = cell(size(result_tagtitle,1),1);
        oldversioncells(:,1) = {1};
        result_tagtitle = horzcat(result_tagtitle,oldversioncells);    end
    if size(result_name,2)==1 % if this is an old results file which does not contain a version number, add in a 1 for the version number
        oldversioncells = cell(size(result_name,1),1);
        oldversioncells(:,1) = {1};
        result_name = horzcat(result_name,oldversioncells);  
    end
    
    if contains(tagname,'CustomTag')
        result_name(dataindex,:) = {tagname 1};
        if dataindex>length(result_data)
            result_data(dataindex).data = result;
            result_tags(tagindex).tagtable = tag;
        else
            result_data(dataindex).data = result_data(dataindex).data|result;
            result_tags(tagindex).tagtable = vertcat(result_tags(tagindex).tagtable,tag);
            result_tags(tagindex).tagtable = sortrows(result_tags(tagindex).tagtable);
        end
        result_data(dataindex).time = time;
        result_tagcolumns(tagindex).tagname = tagcol;
        result_tagtitle(tagindex,:) = {tagname 1};
    else
        if exist('dataindex')
            result_name(dataindex,:) = name;
            result_data(dataindex).data = result;
            result_data(dataindex).time = time;
        end
        if exist('tagindex')
            result_tagtitle(tagindex,:) = name;
            result_tags(tagindex).tagtable = tag;
            result_tagcolumns(tagindex).tagname = tagcol;
        end
    end
    
    if ~isempty(qrsinput)
        result_qrs(qrsinput.lead).qrs = qrsinput;
    end
        
end
