function [ecg,ecgt,fs,name]=getecg(file,leadname)

if ~exist('leadname','var'),leadname={'I','II','III'}';end

ecg=[];
ecgt=[];
fs=[];
group='/Waveforms';
nlead=length(leadname);
%Find ECG lead with most data

nx=zeros(nlead,1);
for i=1:nlead
    try
        info=h5info(file,[group,'/',leadname{i},'/data']);
    catch
        continue;
    end
    cs=[];
    if isfield(info,'ChunkSize'),cs=info.ChunkSize;end
    if length(cs)<2,continue,end
    nx(i)=cs(2);
end
[n,lead]=max(nx);
name=leadname{lead};
if n==0,return,end
[ecg,ecgt,fs]=getwavedata(file,[group,'/',name]);
