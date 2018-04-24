function [wdata,wname,wt,info]=gethdf5wave(hdf5file,wname,wformat)
% [wdata,wname,wt,info]=gethdf5wave('X:\Amanda\TestInputFiles\UVA\BedmasterUnity\NICU_A1-1444723999_2015101.hdf5',cell(0,1),1);
%function [wdata,wname,info]=gethdf5wave(hdf5file,wname)
%
%hdf5file - HDF5 file with wave sign data
%wname - name of waveforms  to retrieve ... 0 or empty => all (default);
%
%wdata - structure with wave sign values
%wname - waveform names retrieved
%info - information about entire HDF5 file

wdata=[];
info=[];
if ~exist('wname','var'),wname=cell(0,1);end
if ~exist('wformat','var'),wformat=1;end

allwave=isempty(wname);
[data,Name,info]=gethdf5data(hdf5file,'/Waveforms',wname);

if allwave
    wname=Name;
end

wdata=data;
nw=length(wdata);
fs=zeros(nw,1);
for i=1:nw
    n=length(wdata(i).x);
    nt=length(wdata(i).t);
    fs(i)=n/nt;    
    wdata(i).fs=fs(i);
    wdata(i).T=[];
end

%Add individual time stamps
if wformat==1
    for i=1:nw
        dt = median(diff(wdata(i).t)); % Amanda added this, it originally was dt = 1;
        tmax = dt*5; % Amanda added this, but she isn't sure if 5 is a good choice
        wdata(i).T=blocktime(wdata(i).x,wdata(i).t,dt,tmax);
    end
end

nv=length(wdata);
if nv==0,return,end
%Put all data into long vectors 
t=[];
x=[];
w=[];
for i=1:nv
    n=length(wdata(i).T);
    if n==0,continue,end
    x=[x;wdata(i).x];    
    t=[t;wdata(i).T];
    w=[w;i*ones(n,1)];
end
%Long matrix output
if wformat==2
    wdata=[w x];
    wt=t;
    return
end

%Matrix output
[wt,~,r]=unique(t);

nt=length(wt);
wdata=NaN*ones(nt,nv);
for i=1:nv
    j=w==i;
    wdata(r(j),i)=x(j);
end
