function [data,name,info]=resultfiledata(rootinfo,name)
%function [data,name,info]=datfiledata(file,name)
%
%rootinfo   root file attributes or result file
%name       name of result datasets to retrieve (empty=default => all) 
%
%data       structure with data and time stamps
%name       name of datasets
%info       attrributes of result file

if ~exist('name','var'),name=cell(0,1);end
if ~exist('rootinfo','var'),rootinfo=[];end
data=[];
result_name=cell(1,0);
result_data=[];

if isstruct(rootinfo)
    if isfield(rootinfo,'file')
        rootfile=rootinfo.file;
    end
else
    rootfile=rootinfo;
    rootinfo=[];
end

[pathstr,root,~]=fileparts(rootfile);
ishdf5=endsWith(rootfile,'.hdf5');
isresult=endsWith(rootfile,'_results.mat');
if ~isresult
    file=fullfile(pathstr,root);
    file=[file,'_results.mat'];
else
    file=rootfile;
end

try
    load(file,'result_data','result_name')
end

info.file=file;
info.rootfile=rootfile;
info.name=result_name;

%Default timestamps in UTC and ms
tunit=1000;
utczero=0;
isutc=true;
dayzero=NaN;

if isfield(rootinfo,'isutc')
    isutc=rootinfo.isutc;
end

if isfield(rootinfo,'utczero')
    utczero=info.utczero;
end

if ~isutc,return,end

if isfield(info,'tunit')
    tunit=info.tunit;
end
if isfield(info,'dayzero')
    dayzero=info.dayzero;
end
info.isutc=isutc;
info.tunit=tunit;
info.dayzero=dayzero;
info.utczero=utczero;

n=length(result_name);
if n==0,return,end
%Find requested names
if ~isempty(name)
    sub=zeros(n,1);
    for i=1:length(name)
        j=strmatch(name{i},result_name);
        if isempty(j),continue,end
        sub(j)=1;
    end
    good=sub>0;
    result_data=result_data(good);
    name=result_name(good);    
else
    name=result_name;        
end
rootfile='';
if isfield(rootinfo,'file')
    rootfile=rootinfo.file;
end

if isempty(rootinfo)
    
load(file,'result_data','result_name')

n=length(name);
data=[];
%Put all result data into default data structure format
for i=1:n
    data(i,:).name=name{i};
    x=result_data(i).data;    
    data(i).x=x;
    data(i).nx=length(x);
    data(i).fs=[];    
    data(i).raw=true;    
    t=result_data(i).time;    
    data(i).t=t;
    data(i).nt=length(t);
    data(i).scale=NaN;
    data(i).offset=NaN;    
end
clear result_data

for i=1:n
    t=data(i).t;
    data(i).t=t-utczero;    
end
