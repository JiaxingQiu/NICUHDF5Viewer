function [d1,d2]=timechanges(y)

ny=length(y);
d1=NaN*ones(ny,1);
d2=NaN*ones(ny,1);

for i=1:length(y)
    y0=y(i);
    wd=15-weekday(datenum(y0,3,1)-1);
    d1(i)=datenum(y0,3,wd,2,0,0);    
    wd=8-weekday(datenum(y0,11,1)-1);
    d2(i)=datenum(y0,11,wd,1,0,0);
end
    
    
