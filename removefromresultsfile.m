function removefromresultsfile(filename,tagcategoryname,tagcategorynum,tagnumber)
    % This removes a particular tag from a results file
    %
    % filename: the input file name with .hdf5 extension
    % tagcategoryname: the name of the tag category from which the tag needs to be removed
    % tagcategorynum: what number (in the tag category box) is the tag category
    % tagnumber: in the tag box, which tag number needs to be removed?
    %
    % Load the Results File:
    resultfilename = strrep(filename,'.hdf5','_results.mat');
    load(resultfilename,'result_vital_name','result_vital_data','result_tags','result_tagcolumns','result_tagtitle','result_vital_time');
    
    index = find(strcmp(result_vital_name, tagcategoryname));
    result_tags(tagcategorynum).tagtable(tagnumber,:) = [];
    result_vital_data(:,index) = zeros(size(result_vital_data(:,index)));
    for t=1:length(result_tags(tagcategorynum).tagtable)
        [~,startindex] = min(abs(result_vital_time-result_tags(tagcategorynum).tagtable(t,1)));
        [~,endindex] = min(abs(result_vital_time-result_tags(tagcategorynum).tagtable(t,2)));
        result_vital_data(startindex:endindex,index) = ones(endindex-startindex+1,1);
    end
    save(resultfilename,'result_vital_data','result_vital_name','result_vital_time','result_tags','result_tagcolumns','result_tagtitle');
end