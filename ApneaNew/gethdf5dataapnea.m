function [data,name,info]=gethdf5data(file,name,window,timeonly)
%function [data,name,info]=gethdf5data(file,name,window,timeonly)
%
%file hdf5 file
%name name of datasets to retrieve (empty=default => all) 
%window time window to retrieve (empty=default => all)
%        start=window(1)
%        stop=window(2)
%timeonly true=> only get time indices (default=false)]
%
%data dataset structure with requested data, time stamps and attributes

if ~exist('name','var'),name=cell(0,1);end
if ~exist('window','var'),window=[];end
if ~exist('timeonly','var'),timeonly=false;end
stop=[];
start=[];
if ~isempty(window)d
    if length(window)==1        
        start=[];
        stop=window;
    else
        start=window(1);
        stop=window(2);
    end
end
if isempty(name)
    name=datanames(file,'/','/data');
end

if ischar(name),name={name};end
%Get all datasets if isempty
info=h5info(file);
data=[];
n=length(name);    
for i=1:n    
    dataset=name{i};    
    data(i,:).name=dataset;
    
%See if dataset exists
    try
        info=h5info(file,dataset);
    catch
        info=[];
    end
    data(i).info=info;
    if isempty(info),continue,end    
    dgroup=[dataset,'/data'];
    tgroup=[dataset,'/time'];
    
%Set default values    
    x=[];
    t=[];
    fac=[];
    cal=[];
    block=1;
    T=1000;
    tunit=1000;
    if ~timeonly
        try
            x=h5read(file,dgroup);         
        end
    end
    try
        t=h5read(file,tgroup);
    end        
    try  
        block=h5readatt(file,dataset,'Readings Per Sample');
    end
    try
        T=h5readatt(file,dataset,'Sample Period (ms)');
    end
    
    block=double(block);
    t=double(t)/tunit;
    T=double(T)/tunit;        
    fs=block/T;
    
%Convert scaling factor to calibration vector used for BedMaster data
%Cal = “Cal Lo, Cal Hi, Grid Lo, Grid Hi”
% The Cal and Grid values are used in a couple of scaling tags as well:
%Scale = (Cal Hi – Cal Lo) / (Grid Hi – Grid Lo)
%Scaled_data = Cal Lo + (Raw Sample – Grid Lo) * Scale *-1
%If Cal Hi is NaN then Scale = -0.025
    try
        fac=h5readatt(file,dataset,'ScaleFactor');
    end
    try
        cal=h5readatt(file,dataset,'Cal');
    end
%Convert calibration to numbers if necessary
    if iscell(cal)
        cal=cal{1};
    end
    if ischar(cal)
        try
          cal=cell2mat(textscan(cal,'%f','Delimiter',','));
        end
    end
    
    if isempty(cal)
        if length(fac)==1
            fac=[0 fac];
        end
        if length(fac)>=2
            cal=zeros(1,4);
            cal(1)=fac(1);
            cal(2)=cal(1)-fac(2);
            cal(4)=1;
        end
    else
        if isempty(fac)
            if length(cal)>=4
                fac(2)=-(cal(2)-cal(1))/(cal(4)-cal(3));
                fac(1)=cal(1)-fac(2)*cal(3);
            end
        end        
    end
           
%Convert to row vectors if necessary    
    if size(x,1)==1
        x=x(:);
    end
    if size(t,1)==1
        t=t(:);
    end
%Find data in window 
    nt=length(t);
    nx=length(x)/nt;

    if ~isempty(stop)
        j=find(t>=stop);
        if ~isempty(j)           
            t(j)=[];
            if block==nx
                j2=(j(1)-1)*block;
                x((j2+1):end)=[];
            end
        end
    end
    if ~isempty(start)
        j=find(t<start);
        if ~isempty(j)           
            t(j)=[];
            if block==nx          
                j1=j(end)*block;
                x(1:j1)=[];
            end
        end        
    end
    if nt>0
        if isempty(start),start=t(1);end        
        if isempty(stop),stop=t(nt);end
    end
    
    data(i).x=x;
    data(i).t=t;        
    data(i).fs=fs;    
    data(i).T=T;
    data(i).block=block;
    data(i).tunit=tunit;    
    data(i).scalefac=fac;
    data(i).cal=cal;
    data(i).window=window;
    data(i).start=start;
    data(i).stop=stop;    
    
end

