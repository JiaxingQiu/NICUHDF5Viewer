d=[1;diff(ecg)];
dt=[0;diff(ecgt)];
flat=d==0&dt<2*tunit/fs;

d0=find(flat|isnan(ecg));
n0=length(d0);
j1=1;
j2=n0;
j=find(diff(d0)>1);
if ~isempty(j)
    j1=[j1;(j+1)];    
    j2=[j;j2];
end
%Number of flat or NaN points in each segment
nf=j2-j1+1;
sub=nf>=fs*fmin;
j1=j1(sub);
j2=j2(sub);
