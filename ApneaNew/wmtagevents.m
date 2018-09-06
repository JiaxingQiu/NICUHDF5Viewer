function [tag,tagname,tag0]=wmtagevents(p,pgood,pt,ps)  

if ~exist('ps','var'),ps=4;end
p=p(:);
n=length(p);
if ~exist('pt','var')
    pgood=true(n,1);
end
p(~pgood)=0;
if ~exist('pt','var')   
    pt=(1:n)'/ps;
end
%tag=[s(:) e(:)-s(:)+1 wad(:) nna(:) t0(:) t1(:) gapl(:) gapr(:)];
tagname = {'ix' 'dur' 'wad' 'nna' 'st' 'et' 'gap1' 'gapr'}';
nc=length(tagname);
tag=zeros(0,nc);
tag0=zeros(0,nc);

%Find start and end points of possible events
j=find(p>0.1);
if isempty(j),return,end

g=find(diff(j)>1);
s=j([1;(g+1)])-1;
s(s<1)=1;
e=j([g;length(j)])+1;
e(e>n)=n;
dur=e-s+1;
%j=e-s>2;
j=dur>1;
s=s(j); 
e=e(j);
n=length(s);
tag=zeros(n,nc);
if n==0,return,end

%Find weighted apnea duration (WAD) and number of missing points in CI

% wad = [];
% nna = [];
% gapl = [];
% apr = [];
% nna = repelem(0,n);
% wad = repelem(0,n);

%tagname = {'ix' 'dur' 'wad' 'nna' 'st' 'et' 'gap1' 'gapr'}';
nna=zeros(n,1);
wad=zeros(n,1);
for i=1:n
     ix = s(i):e(i);
%     temp = ina(fs*ix/ps);
%     temp(isnan(temp)) = [];
%     nna(i) = sum(temp);
    temp = p(ix);
    temp(isnan(temp)) = [];
    wad(i) = (sum(temp) - 0.5*(p(s(i)) + p(e(i))))/ps;
end
%Include events with WAD > 2 seconds and less than 200 missing points 
j=nna<=200&wad>=2;
s=s(j); 
e=e(j); 
wad=wad(j); 
nna = nna(j);   
n = length(s);
tag=zeros(n,nc);
if n==0,return,end
%Find gaps to adjacent events
gap=[];
if n>1
    gap = (s(2:n)-e(1:(n-1))+2)/ps;
end
gapl=[Inf;gap]; 
gapr=[gap;Inf];
t0=pt(s);
t1=pt(e);
tag=[s e-s+1 wad nna t0 t1 gapl gapr];    
% if n<=1
%     gapl = repelem(Inf,length(s));
%     gapr = repelem(Inf,length(s));
%     return
% end    
j=wad>=5|gapl<=10|gapr<=10;
tag=tag(j,:);
tag0=tag;
n=size(tag,1);
if n<2,return,end
n0=n;
%Merge events
dg=3;
tag=tag0(1,:);
n=1;
for i=2:n0
    if tag0(i,7)>dg
        n=n+1;
        tag(n,:)=tag0(i,:);
        continue
    end
    e=tag0(i,1)+tag0(i,2)-1;
    tag(n,2)=e-tag(n,1)+1;    
    tag(n,3)=tag(n,3)+tag0(i,3);
    tag(n,4)=tag(n,4)+tag0(i,4);    
    tag(n,6)=pt(e);
    tag(n,8)=tag0(i,8);
end
