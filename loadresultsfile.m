function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,name,result,time,tag,tagcol,qrsinput)
    % Find the Result Filename
    if contains(filename,'.hdf5')
        resultfilename = strrep(filename,'.hdf5','_results.mat');
    else
        resultfilename = strrep(filename,'.mat','_results.mat');
    end
    % If the file does not already exist, create a file
    if ~exist(resultfilename,'file')
        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = createresultsfile(name,result,time,tag,tagcol,qrsinput);
    else
        load(resultfilename,'result_name','result_data','result_tags','result_tagcolumns','result_tagtitle');
        % Load qrs separately because old versions of the results files don't have it
        varinfo = who('-file',resultfilename);
        if ismember('result_qrs',varinfo)
            load(resultfilename,'result_qrs')
        else
            result_qrs = struct;
        end
        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(filename,name,result,time,tag,tagcol,qrsinput,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
    end
end
