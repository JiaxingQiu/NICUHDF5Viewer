if ~exist('dayfile','var')   
    daydir='\\hscs-share2\centralroot\Research\CAMA\PreVent\UVA\';    
    dayfile=[daydir,'Bed09_Day0031.mat'];
%    dayfile=[daydir,'Bed23_Day0690.mat'];    
end

fs=240;
CIfs=60;
gain=400;
filt=1;
ps=4;
ns=30;
%d=4;
d=fs/CIfs;

load(dayfile,'T_ekg1','ekg1')

T_ekg1=double(T_ekg1)+1;
tic,[qt,qb,qgood,x,xt]=tombqrs(ekg1,T_ekg1/fs,400,fs);toc
load(dayfile,'T_resp','resp')
T_resp=double(T_resp+d)/fs;
%Remove breath marks
[resp,marker]=RR2raw_V2(double(resp));

[p,pt,pgood]=tombstone(resp,T_resp,qt(qgood),qb(qgood),CIfs);
[tag,tagname,tag0]=wmtagevents(p,pgood,pt,ps);

load(dayfile,'T_aprobU','T_aprob','T_std')
load(dayfile,'aprobU','aprob','std')
wp=double(aprobU)/1000;
wsd=double(std)/1000;
wgood=wp>=0&wp<=1&wsd>0;
clear std
wt=double(T_aprobU+60)/fs;
wp(~wgood)=0;
wsd(~wgood)=NaN;
[wtag,~,wtag0]=wmtagevents(wp,ps,wt);

tags=[tag;wtag];
source=[ones(size(tag,1),1);2*ones(size(wtag,1),1)];

ntags=size(tags,1);
ind=zeros(ntags,2);
dup=zeros(ntags,2);
dw=zeros(ntags,1);

for i=1:size(tags,1)
    for j=1:2
        k=find(source==j);
        dd=tags(k,5)-tags(i,5);
        [dd1 jj]=min(abs(dd));
        dup(i,j)=dd1;
        ind(i,j)=k(jj);
    end
    dw(i)=min(abs(tags(i,5)-wt(wgood)));
end
a=find(tags(:,3)>10);
a(max(dup(a,:),[],2)<2)=[];
a(dw(a)>0)=[];
