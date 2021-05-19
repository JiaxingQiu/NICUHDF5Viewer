function info=getfileinfo(file,noresult)
%function [data,info,name]=getdata(file,name)
%
%file       file name to retrieve information
%noresult   flag to not get results (default=false)
%
%info       structure with time stamps and all dataset attributes/names

%Find file type

if ~exist('noresult','var'),noresult=false;end

info=[];
ishdf5=endsWith(file,'.hdf5');
isdat=endsWith(file,'.dat');
ismat=endsWith(file,'.mat');
isresult=endsWith(file,'_results.mat');

if ishdf5
    info=h5fileinfo(file);
end
if isdat
    info=datfileinfo(file);        
end
if ismat
    info=matfileinfo(file);        
end
if isresult
    info=file;
end
if ~noresult    
    info=resultfileinfo(info);
end

end

function info=resultfileinfo(info)
%function info=resultfileinfo(file)
%
%info       structure with information about root file or rootfile name
%
%info       structure with time stamps and datasets from result file added

if isstruct(info)
    file='';
    if isfield(info,'file')
        file=info.file;        
    end
else
    file=info;
end

if isfield(info,'alldata')
    data=info.alldata;
else
    data=[];
end
n=length(data);

if ~isfield(info,'resultfile')
    resultfile=file;
    isresult=endsWith(file,'_results.mat');
    if ~isresult
        [pathstr,root,~]=fileparts(file);    
        resultfile=fullfile(pathstr,root);
        resultfile=[resultfile,'_results.mat'];
    end
else
    resultfile=info.resultfile;
end

if isempty(dir(resultfile))
    resultfile='';
end

info.resultfile=resultfile;

result_name=cell(0,2);
if isfield(info,'resultname')
    result_name=info.resultname;
else
    try
        load(resultfile,'result_name')
    end
end

info.resultname=result_name;
n=size(result_name,1);

if n==0,return,end

result_data=[];
result_tags=[];
result_tagcolumns=[];
result_tagtitle=[];

try
    load(resultfile,'result_data')
end

try
    load(resultfile,'result_tags')
end

try
    load(resultfile,'result_tagcolumns')
end

try
    load(resultfile,'result_tagtitle')
end

if length(result_data)~=n,return,end

if n>length(result_tags)
    disp(['Error using results from file: ' file])
    disp('Error caused by a bad previous version of BAP generating a bad results file.')
    disp('Please delete results file and re-run algorithms.')
    disp('For more information about this error, see https://github.com/UVA-CAMA/NICUHDF5Viewer/issues/22')
    return
end

%Default timestamps in UTC and ms
tunit=1000;
timezero=0;
isutc=true;
dayzero=0;

if isfield(info,'isutc')
    isutc=info.isutc;
end

if isfield(info,'timezero')
    timezero=info.timezero;
end

if isfield(info,'tunit')
    tunit=info.tunit;
end
if isfield(info,'dayzero')
    dayzero=info.dayzero;
end

k=length(data);

%Put all result data into default data structure format
for j=1:n
    i=j+k;
    name=result_name{j,1};
    data(i,:).name=name;
    data(i).fixedname=fixedname(name);
    info.name{i,1}=name;
    info.fixedname{i,1}=fixedname(name);
    x=result_data(j).data; 
    t=result_data(j).time;
    if isutc
        t=t-timezero;
%     else   % we need to remove this because if we have results files in ms since time zero, the isutc flag will fail, but then the program will think the data is in days, which it isn't. Unfortunately, by removing this, we will no longer be able to use old results files which have tags stored as days
%         t=round((t-dayzero)*86400*tunit);
    end
    if isempty(x) % If there is no continuous result data (i.e. if this is just binary tags), store tag time points in a binary array
        tglobal = info.times+timezero;
        tag = result_tags(j).tagtable;
        [x,t] = resultfromtags(tag,result_tagcolumns(j),tglobal,info);
        t = t-timezero;
%         t = info.times;
    end
    data(i).x=x;
    data(i).nx=length(x);
    data(i).fs=[];    
    data(i).raw=true;    
    data(i).t=t;
    data(i).nt=length(t);
    data(i).scale=NaN;
    data(i).offset=NaN;    
end

info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.timezero=timezero;
info.alldata=data;

end