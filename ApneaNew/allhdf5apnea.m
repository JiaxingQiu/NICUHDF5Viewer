if ~exist('datdir','var')
    datdir='X:\PreVent\WUSTL\';
end

if ~exist('leadname','var')
    leadname={'/Waveforms/I','/Waveforms/II','/Waveforms/III'}';
end

if ~exist('respname','var')
    respname='/Waveforms/Resp';
end

if ~exist('CWRU','var')
    CWRU=false;
end

if ~exist('dw','var')
    dw=12*3600;
end

D=dir([datdir,'*.hdf5']);
nf=length(D);
hdf5file=cell(nf,1);
for i=1:nf
    name=D(i).name;
    hdf5file{i}=[datdir,name];    
end

apnea=[];

for f=1:nf

tic

file=hdf5file{f};

start=0;
try
    start=h5readatt(file,'/','Start Time');
    start=double(start)/1000;    
end
fstart=utc2local(start);
disp(datestr(fstart))

stop=0;
try
    stop=h5readatt(file,'/','End Time');
    stop=double(stop)/1000;    
end
fend=utc2local(stop);
disp(datestr(fend))

dur=stop-start;
if stop-start>dw
    window=start+[0 dw];
    dur=dw;
else
    window=[];
end
%Get EKG and resp waveforms

nlead=length(leadname);
lead=1;
%Find lead with most data in window
if nlead>1
    tdata=gethdf5data(file,leadname,window,true);                
    nt=zeros(nlead,1);
    for i=1:nlead
        nt(i)=length(tdata(i).t);
    end
    [~,lead]=max(nt);
end
ecgname=leadname{lead}; 
[resp,respt,respfs]=getwavedata(file,respname,window,1);
[ecg,ecgt,ecgfs]=getwavedata(file,ecgname,window);    


%Filter out high frequency noise in waveforms at CWRU

if CWRU
    [b,a]=butter(5,2*40/ecgfs,'low');
    ecg=filtfilt(b,a,ecg);
end

if CWRU
    [b,a]=butter(5,2*5/respfs,'low');
    resp=filtfilt(b,a,resp);    
    n=length(resp);
    resp=mean(reshape(resp,4,n/4));
    respt=respt(4:4:n);
    respfs=respfs/4;
end

%Convert time stamps to relative to start time 0
respt=respt-start;
ecgt=ecgt-start;

[qt,qb]=tombqrs(ecg,ecgt,ecgfs);
[p,pt,pgood,psd]=tombstone(resp,respt,respfs,qt,qb);
[tag,tagname,tag0]=wmtagevents(p,pgood,pt);

disp(sum(tag(:,3)>10))

apnea(f,:).file=file;
apnea(f).start=datestr(fstart);
apnea(f).utc=start;
apnea(f).window=dur;
apnea(f).pt=pt;
apnea(f).p=p;
apnea(f).psd=psd;
apnea(f).pgood=pgood;
apnea(f).tag=tag;
apnea(f).tagname=tagname;

toc

end
