if ~exist('file','var')
    file='20181119102552_Prevent_Prentice_2024_MC2_20181120.hdf5';
end
if ~exist('fignum','var')   
    fignum=1;
end
leads={'ECGI','ECGII','ECGIII'};
tic,info=getfileinfo(file);toc

for i=1:length(leads)
    ecgname=leads{i};
    tic,[ecg,ecgt,ecgfs]=formatdata(ecgname,info);toc
    ecgt=ecgt/1000;
    if isempty(ecg),continue,end
    tic,[qt,qecg,qs]=getqrs(ecg,ecgt,ecgfs);toc
    tic,[hr,hrt,hrfs]=formatdata('HR',info);toc
    hrt=hrt/1000;    
    tic,[qb,qgood,rr,rrt,drop]=qrsgood(qt);toc
    rrgood=drop==0;
    break
end
titstr=strrep(file,'_',' ');
titstr=[titstr ' ' ecgname];
figure(fignum)
clf
plot(hrt/3600,hr,'.')
hold on
plot(rrt(rrgood)/3600,60000./rr(rrgood),'.')
xlabel('Hour')
title(titstr)

figure(fignum+1)
clf
plot(ecgt/3600,ecg)
hold on
plot(qt(qgood)/3600,qecg(qgood),'*')
xlabel('Hour')
title(titstr)
