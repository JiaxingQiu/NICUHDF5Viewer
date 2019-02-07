function [data,name,time,tagtitles,tagcolumns,tags] = getresultsfile2(fullfilename)
if contains(fullfilename,'.hdf5')
    resultsfilename = strrep(fullfilename,'.hdf5','_results.mat');
else
    resultsfilename = strrep(fullfilename,'.mat','_results.mat');
end

% resultsfilename = [erase(fullfilename,".hdf5") '_results.mat'];
if exist(resultsfilename, 'file') == 2
    load(resultsfilename,'result_*');
    if ~exist('result_data','var') % if it is an old version of the results file
        data = 'Delete old result file!';
        name = [];
        time = [];
        tagtitles = [];
        tagcolumns = [];
        tags = [];
    else
        %Put all data into long vectors 
        t=[];
        x=[];
        v=[];
        i = 1; % this counts the index of the original result_data
        j = 1; % this counts the index of the new data vectors when SIQ is added

        nv = length(result_data);
        while i<=nv
            n=length(result_data(j).time);
%             if n==0,continue,end
            x=[x;result_data(j).data];    
            t=[t;result_data(j).time];
            v=[v;i*ones(n,1)];
            i = i+1;
            j = j+1;
        end
        %Matrix output
        [vt,~,r]=unique(t);
        nt=length(vt);
        matrixformat=NaN*ones(nt,nv);
        for i=1:nv
            j=v==i;
            matrixformat(r(j),i)=x(j);
        end

        data = matrixformat;
        name = result_name;
        time = vt;
        tagtitles = result_tagtitle;
        tagcolumns = result_tagcolumns;
        tags = result_tags;
    end
else
    data = [];
    name = [];
    time = [];
    tagtitles = [];
    tagcolumns = [];
    tags = [];
end