function addtoresultsfile(filename,vname,vresult,vtime,tag,tagname)
    % This saves results that were generated from vital sign data into a
    % separate file
    %
    % filename: the input file name with .hdf5 extension
    % vname: the name of the results file
    % vresult: the results
    % vtime: the time vector
    if contains(filename,'.hdf5')
        resultfilename = strrep(filename,'.hdf5','_results.mat');
    else
        resultfilename = strrep(filename,'.mat','_results.mat');
    end
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
            index = find(strcmp(result_vital_name, vname));
%             index = find(contains(result_vital_name,vname));
            if contains(vname,'CustomTag')
                result_vital_data(:,index) = result_vital_data(:,index)|vresult;
                result_tags(index).tagtable = vertcat(result_tags(index).tagtable,tag);
                result_tags(index).tagtable = sortrows(result_tags(index).tagtable);
            else
                result_vital_data(:,index) = vresult;
                result_tags(index).tagtable = tag;
            end
        else
            index = length(result_vital_name)+1;
            result_vital_name{index,1} = vname;
            result_vital_data(:,index) = vresult;
            result_tags(index).tagtable = tag;
        end
        result_vital_time = vtime;
        result_tagcolumns = tagname;
        result_tagtitle{index,1} = vname;
    end
    save(resultfilename,'result_vital_data','result_vital_name','result_vital_time','result_tags','result_tagcolumns','result_tagtitle');
end