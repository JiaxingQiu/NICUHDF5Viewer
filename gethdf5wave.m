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

if ~exist('wname','var'),wname='/Waveforms';end
if ~exist('wformat','var'),wformat=0;end

[wdata,~,info]=gethdf5data(hdf5file,wname);

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
% if wformat==1
    for i=1:nw
        dt = median(diff(wdata(i).t)); % Amanda added this, it originally was dt = 1;
        tmax = dt; % Amanda added this, but she isn't sure if it is a good choice
        wdata(i).t=blocktime(wdata(i).x,wdata(i).t,dt,tmax);
    end
% end

[wdata,wt,wname]=vdataformat(wdata,wformat); % Convert to matrix format
wt = wt*1000; % convert to ms