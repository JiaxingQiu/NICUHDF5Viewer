function addtoresultsfilecomplex(filename,name,result,time,tag,tagname,vorw)
    % This saves results that were generated from vital sign data into a
    % separate file
    %
    % filename: the input file name with .hdf5 extension
    % vname: the name of the results file
    % vresult: the results
    % vtime: the time vector
    
    % If we are loading in a matrix of data (i.e. for waveform or vital
    % signs datasets)
    nvar = size(name,1);
    if nvar>1
        allnames = name;
        alldata = result';
    end
    
    for n=1:nvar
        if nvar>1
            name = allnames(n);
            result = alldata(n,:);
        end
        resultfilename = strrep(filename,'.hdf5','_results.mat');
        if ~exist(resultfilename,'file') % If the file doesn't exist yet
            if vorw == 1
                result_vital_name{1,1} = name;
                result_vital_data(:,1) = result;
                result_vital_time = time;
                result_wave_name = [];
                result_wave_data = [];
                result_wave_time = [];
            else
                result_vital_name = [];
                result_vital_data = [];
                result_vital_time = [];
                result_wave_name{1,1} = name;
                result_wave_data(:,1) = result;
                result_wave_time = time;
            end
            result_tags(1).tagtable = tag;
            result_tagcolumns = tagname;
            result_tagtitle{1,1} = name;
        else % check to see if results already contain this name
            load(resultfilename,'result_vital_name','result_wave_name','result_vital_data','result_wave_data','result_vital_time','result_wave_time','result_tags','result_tagcolumns','result_tagtitle');
            if vorw == 1
                if any(strcmp(result_vital_name,name))
                    index = find(contains(result_vital_name,name));
                else
                    index = length(result_vital_name)+1;
                    result_vital_name{index,1} = name;
                end
                result_vital_data(:,index) = result;
                result_vital_time = time;
            else
                if any(strcmp(result_wave_name,name))
                    index = find(contains(result_wave_name,name));
                else
                    index = length(result_wave_name)+1;
                    result_wave_name{index,1} = name;
                end
                result_wave_data(:,index) = result;
                result_wave_time = time;
            end
            result_tags(index).tagtable = tag;
            result_tagcolumns = tagname;
            result_tagtitle{index,1} = name;
        end
        save(resultfilename,'result_vital_name','result_wave_name','result_vital_data','result_wave_data','result_vital_time','result_wave_time','result_tags','result_tagcolumns','result_tagtitle');
    end
end