fac=[-0.0356 0.0013];
datdir='\\hscs-share2\centralroot\Research\CAMA\Prevent\Matlab\CWRU\1001 sample graphs to UVa to improve Noise Filtering';

D=dir(fullfile(datdir,'*.dat'));
nf=length(D);
noise=[];
for i=1:nf
    file=fullfile(datdir,D(i).name);
    
    fid=fopen(file);
    rawdata=fread(fid,[4 inf],'int16','ieee-be');
    fclose(fid);
    rawdata=rawdata';
    rawdata=double(rawdata);
    rawdata=fac(2)*rawdata+fac(1);
    rawspo2=100*rawdata(:,3);
    rawhr=250*rawdata(:,4);
    noise(i,1).file=file;
    noise(i).rawspo2=rawspo2;
    noise(i).rawhr=rawhr;    
end

save noiserawdata

clear

load noiserawdata noise nf D datdir fac

ns=1;

for i=1:nf

disp(D(i).name)    
file=noise(i).file;

rawspo2=noise(i).rawspo2;
rawhr=noise(i).rawhr;

[spo2,spo2good,hr,hrgood,t]=noisefilter(rawspo2,rawhr,ns);

noise(i).t=t;
noise(i).spo2=spo2;
noise(i).spo2good=spo2good;
noise(i).hr=hr;
noise(i).hrgood=hrgood;

disp([sum(~spo2good) sum(~hrgood)]) 

name=strrep(D(i).name,'_',' ');

figure(1)
clf

subplot(2,1,1)
plot(t(spo2good)/3600,spo2(spo2good),'.b')
hold on
plot(t(~spo2good)/3600,spo2(~spo2good),'.r')
title(name)

subplot(2,1,2)
plot(t(hrgood)/3600,hr(hrgood),'.b')
hold on
plot(t(~hrgood)/3600,hr(~hrgood),'.r')

pause

end

