function [wdata,wname,info]=gethdf5wave(hdf5file,sigstart,sigsamples,wname,wformat)
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
if ~exist('wformat','var'),wformat=0;end

wnamedata = horzcat(wname,'/data');

allwave=isempty(wnamedata);
[data,Name,info]=gethdf5data(hdf5file,'/Waveforms',wnamedata,sigstart,sigsamples);
if allwave
    wnamedata=Name;
end

wdata=data;
nw=length(wdata);
fs=zeros(nw,1);
% rpt = zeros(nw,1);
% dt = zeros(nw,1); % added this: dt is the number of seconds between samples
dt = median(diff(wdata.t)); % added this: dt is the number of seconds between samples
for i=1:nw
    n=length(wdata(i).x);
    nt=length(wdata(i).t);
    fs(i)=n/nt/dt; % added the dt here to account for samples not necessarily being taken once per second
    fs(i) = h5readatt(hdf5file,['/Waveforms/' wname],'Sample Frequency (Hz)');
%     rpt(i) = h5readatt(hdf5file,['/Waveforms/' wname],'Readings Per Time');
%     dt(i) = rpt(i)/fs(i);
    wdata(i).fs=fs(i);
    wdata(i).T=[];
end

%Add individual time stamps
if wformat==1
    for i=1:nw
        wdata(i).T=blocktime(wdata(i).x,wdata(i).t,dt);
    end
end