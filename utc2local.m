function [d,dv,off]=utc2local(utc,method)
% Converts a UNIX timestamp (UTC based) to a (local!) MATLAB date
if ~exist('method','var')
    method=0;
end
n=length(utc);
dv=NaN*ones(n,6);
off=zeros(n,1);
d=NaN*ones(n,1);
if method>0
    cal=java.util.Calendar.getInstance;
    for i=1:n
        cal.setTimeInMillis(1000*utc(i));
        dv(i,:)=[cal.get(cal.YEAR) cal.get(cal.MONTH)+1 cal.get(cal.DAY_OF_MONTH) ...
            cal.get(cal.HOUR_OF_DAY) cal.get(cal.MINUTE) cal.get(cal.SECOND)];
        off(i)=cal.get(cal.DST_OFFSET)/1000;
    end
    d=datenum(dv);
    return
end
gm=datenum(1970,1,1)+utc/86400;
dv=datevec(gm);
dv(:,4)=dv(:,4)-5;
d=datenum(dv);
y=dv(:,1);
yy=unique(y);
for i=1:length(yy)
    y0=yy(i);
    j=find(y==y0);
    dd=d(j);
    wd=15-weekday(datenum(y0,3,1)-1);
    d1=datenum(y0,3,wd,2,0,0);    
    wd=8-weekday(datenum(y0,11,1)-1);
    d2=datenum(y0,11,wd,1,0,0);
    k=j(dd>=d1&dd<d2);
    off(k)=3600;
    dv(k,4)=dv(k,4)+1;
    d(k)=datenum(dv(k,:));
end
    
    
