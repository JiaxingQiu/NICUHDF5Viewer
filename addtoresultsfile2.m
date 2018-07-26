function addtoresultsfile2(filename,name,result,time,tag,tagname)
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
end