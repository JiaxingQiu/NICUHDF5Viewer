function info=resultfileinfo(file)
%function [data,name,info]=datfiledata(file,name)
%function info=getfileinfo(file)
%
%file       root file
%
%info       structure with time stamps and dataset attributes/names
%name       name of datasets
%data       stucture with dataset attributes and timestamps
%
%rootinfo   root file attributes or result file
%name       name of result datasets to retrieve (empty=default => all) 
%
%data       structure with data and time stamps
%name       name of datasets
%info       attrributes of result file

if isstruct(file)
    info=file;
    file='';
    if isfield(info,'file')
        file=info.file;        
    end
else
    info.file=file;
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
    info.resultfile=resultfile;
else
    resultfile=info.resultfile;
end

%Default timestamps in UTC and ms
tunit=1000;
utczero=0;
isutc=true;
dayzero=0;

if isfield(info,'isutc')
    isutc=info.isutc;
end

if isfield(info,'utczero')
    utczero=info.utczero;
end

if isfield(info,'tunit')
    tunit=info.tunit;
end
if isfield(info,'dayzero')
    dayzero=info.dayzero;
end

% if isfield(info,'name')
%     name=info.name;
% end
% if isfield(info,'fixedname')
%     fixedname=info.fixedname;
% end
result_name=cell(1,0);
if isfield(info,'resultname')
    result_name=info.resultname;
else
    try
        load(resultfile,'result_name')
    end
    info.resultname=result_name;
end

n=length(result_name);

result_data=[];

try
    load(resultfile,'result_data')
end

if length(result_data)~=n,return,end

k=length(data);

%Put all result data into default data structure format
for j=1:n
    i=j+k;
    name=result_name{j};
    data(i,:).name=name;
    data(i).fixedname=fixedname(name);
    info.name{i,1}=name;
    info.fixedname{i,1}=fixedname(name);
    x=result_data(j).data;    
    data(i).x=x;
    data(i).nx=length(x);
    data(i).fs=[];    
    data(i).raw=true;    
    t=result_data(j).time;
    if isutc
        t=t-utczero;
    else
        t=round((t-dayzero)*86400*tunit);
    end
    data(i).t=t;
    data(i).nt=length(t);
    data(i).scale=NaN;
    data(i).offset=NaN;    
end

info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.utczero=utczero;
info.alldata=data;

