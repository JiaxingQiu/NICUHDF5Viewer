function addtoresultsfile(filename,vname,vresult,vtime,tag,tagname)
    % This saves results that were generated from vital sign data into a
    % separate file
    %
    % filename: the input file name with .hdf5 extension
    % vname: the name of the results file
    % vresult: the results
    % vtime: the time vector
    resultfilename = strrep(filename,'.hdf5','_results.mat');
    if ~exist(resultfilename,'file')
        result_vital_name{1,1} = vname;
        result_vital_data(:,1) = vresult;
        result_vital_time = vtime;
        result_tags(1).tagtable = tag;
        result_tagcolumns = tagname;
        result_tagtitle{1,1} = vname;
    else
        % check to see if results already contain this name
        load(resultfilename,'result_vital_name','result_vital_data','result_tags','result_tagcolumns','result_tagtitle');
        if any(strcmp(result_vital_name,vname))
            index = find(contains(result_vital_name,vname));
        else
            index = length(result_vital_name)+1;
            result_vital_name{index,1} = vname;
        end
        result_vital_data(:,index) = vresult;
        result_vital_time = vtime;
        result_tags(index).tagtable = tag;
        result_tagcolumns = tagname;
        result_tagtitle{index,1} = vname;
    end
    save(resultfilename,'result_vital_data','result_vital_name','result_vital_time','result_tags','result_tagcolumns','result_tagtitle');
end