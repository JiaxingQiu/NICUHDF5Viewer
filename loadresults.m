function [isfile,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresults(filename)
    % isfile is a 1 if the results file exists and a 0 if it does not
    
    % Find the Result Filename
    if contains(filename,'.hdf5')
        resultfilename = strrep(filename,'.hdf5','_results.mat');
    elseif contains(filename,'.mat')
        resultfilename = strrep(filename,'.mat','_results.mat');
    elseif contains(filename,'.dat')
        resultfilename = strrep(filename,'.dat','_results.mat');
    end
    
    % Check if file exists
    if exist(resultfilename,'file')
        load(resultfilename,'result_name','result_data','result_tags','result_tagcolumns','result_tagtitle');
        % Load qrs separately because old versions of the results files don't have it
        varinfo = who('-file',resultfilename);
        if ismember('result_qrs',varinfo)
            load(resultfilename,'result_qrs')
        else
            result_qrs = struct;
        end
        isfile = 1;
    else
        result_name = [];
        result_data = [];
        result_tags = [];
        result_tagcolumns = [];
        result_tagtitle = [];
        result_qrs = [];
        isfile = 0;
    end