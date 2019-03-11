function [utc,off]=local2utc(d)
%function [utc,off]=local2utc(d)
%
%d    vector of Matlab dates in EST
%
%utc  corresponding vector of time in UTC
%off  offset from GMT to EST in seconds

n=length(d);
dv=datevec(d);
utc=86400*(d-datenum(1970,1,1));
y=dv(:,1);    
yy=unique(y);
off=5*3600*ones(n,1);
for i=1:length(yy)
    y0=yy(i);
    [d1,d2]=timechanges(y0);    
    j=find(y==y0);
    dd=d(j);
    k=j(dd>=d1&dd<d2);
    off(k)=off(k)-3600;
end
utc=utc+off;    
    
