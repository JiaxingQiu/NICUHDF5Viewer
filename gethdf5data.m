function [data,name,info]=gethdf5data(file,name,window,timeflag)
%function [data,name,info]=gethdf5data(file,name,window,timeonly)
%
%file       hdf5 file
%name       name of datasets to retrieve (empty=default => all) 
%window     time window to retrieve (empty=default => all)
%           start=window(1)
%           stop=window(2)
%timeflag   1=> corrected timestamps (default)
%           0=> original timestamps
%           2=> just original timestamps
%           3=> just corrected timestamps
%
%data       dataset structure with requested data, time stamps and attributes
%name       name of datasets

if ~exist('name','var'),name=cell(0,1);end
if ~exist('window','var'),window=[];end
if ~exist('timeflag','var'),timeflag=1;end

timeonly=timeflag>=2;
nojitter=rem(timeflag,2)~=0;

%See if file exists
info=[];
data=[];
try
    info=h5info(file);
end
if isempty(info)
    name=[];
    return
end

stop=[];
start=[];
if ~isempty(window)
    if length(window)==1        
        start=[];
        stop=window;
    else
        start=window(1);
        stop=window(2);
    end
end

group='/';
if ischar(name)    
    str=name;
    name={str};
    if strcmp('/',str)
        group=str;
        name=[];
    end    
    if strcmp('/VitalSigns',str)
        group=str;
        name=[];
    end
    if strcmp('/Waveforms',str)
        group=str;
        name=[];
    end
end    

%Get all datasets if empty
%Otherwise, find which requested dataset groups exist
if isempty(name)
    name=datanames(file,group,'/data');
else
    n=length(name);
    good=true(n,1);
    for i=1:n
        try
            info=h5info(file,name{i});
        catch
            good(i)=0;
        end
    end
    name=name(good);
end

n=length(name);    
for i=1:n    
    dataset=name{i};    
    data(i,:).name=dataset;    
    info=h5info(file,dataset);
    data(i).info=info;
    dgroup=[dataset,'/data'];
    tgroup=[dataset,'/time'];
    
%Set default values    
    x=[];
    t=[];
    fac=[];
    cal=[];
    block=[];
    fs=[];
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
    
    %Convert to row vectors if necessary
    [nr,nc]=size(x);
    if nr>1
        if nc>=nr
            x=x(1,:);
        else
            if nc>1
                x=x(:,1);
            end
        end
    end
        
    if size(x,1)==1
        x=x(:);
    end
    if size(t,1)==1
        t=t(:);
    end
   
%Find data in window 
    nt=length(t);
    nx=length(x)/nt;
    
    try  
        block=h5readatt(file,dataset,'Readings Per Sample');
    end
    
    if isempty(block)
        block=nx;
    end

    try
        fs=h5readatt(file,dataset,'Sample Frequency (Hz)');
    end
    
    try
        T=h5readatt(file,dataset,'Sample Period (ms)');
    end    
    
    block=double(block);
    t=double(t)/tunit;
    if isempty(fs)
        T=double(T)/tunit;        
        fs=block/T;
    else
        T=block/fs;
    end        

%Find increasing time samples with no jitter if requested
    dt=floor(T);
    if nojitter
        t=fixjitter(t,dt);
    end
    
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
%        cal=h5readatt(file,dataset,'Cal');
        cal=h5readatt(file,dgroup,'Cal');        
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
%     if nt>0
%         if isempty(start),start=t(1);end        
%         if isempty(stop),stop=t(nt);end
%     end
    
    data(i).x=x;
    data(i).t=t;
    data(i).fs=fs;    
    data(i).T=T;
    data(i).dt=dt;    
    data(i).block=block;
    data(i).tunit=tunit;    
    data(i).scalefac=fac;
    data(i).cal=cal;
    data(i).window=window;
    if nt>0        
        data(i).start=t(1);
        data(i).stop=t(nt);
    end

    
end

end

function [t,d,st]=fixjitter(t,dt)
%function [t,d,st]=fixjitter(t,dt)
%
%t      original time stamps in seconds
%dt     time between samples (default 1 second)
%
%t      increasing time stamps with minimum time between samples
%d      cumulative jitter
%st     ideal times without jitter

if ~exist('dt','var'),dt=1;end

nt=length(t);
st=(1:nt)'*dt;
d=cummin(t-st,'reverse');
t=st+d;

end