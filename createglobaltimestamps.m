function vt = createglobaltimestamps(hdf5file,VorW)
% Reads in all the timestamps from either all of the vital signs or the
% waveforms, then creates a matrix of all of the unique values. Waveform
% timestamps have NOT been run through blocktime. The output is in ms in
% utc time. (Format: 1.xx * 10^12)
% 
% file = full filepath string
% 
% vorw == 1 : vital signs
% vorw == 2 : waveforms
% 

%% Find all the unique vital sign or waveform timestamps
if VorW==1
    name='/VitalSigns';
elseif VorW==2
    name='/Waveforms';
end
window = []; % retrieve all time
timeflag = 3; % only grab corrected timestamps
[data,name,~]=gethdf5data(hdf5file,name,window,timeflag);

n=length(data);
xt=[];

for i=1:n
    xt=[xt;data(i).t];
end

[t,~,~]=unique(xt);

%% Run blocktime on waveforms

% Since blocktime computes the blocksize based on the length of the data,
% we need to create a fake data variable that is the right length so that
% it will compute the correct block size. This is a little silly because we
% could easily enter the sampling frequency directly - however - in the
% interest of keeping just one function in this code and not creating a
% blocktime2, I am going to use this workaround to keep the code
% streamlined. Future generations or future me are free to change this if
% they so prefer. Happy coding!

if VorW==2
    n=length(name);
    block = zeros(n,1);
    for i=1:n    
        dataset=name{i};    
        try
            block(i)=h5readatt(hdf5file,dataset,'Readings Per Sample');
        catch
            disp('No Readings Per Sample attribute available');
        end       
    end
    if length(unique(block))>1 % if the block sizes are different for the different signals, you need to run blocktime for each individual signal
        Tbig = [];
        for i=1:n
            fakedata = nan*ones(block(i)*length(t),1);
            [T,~,~]=blocktime(fakedata,t);
            Tbig=[Tbig;T];
        end
        [t,~,~]=unique(Tbig);
    else
        % If all the block sizes are the same, we only need to run blocktime once
        fakedata = nan*ones(block(1)*length(t),1);
        [t,~,~]=blocktime(fakedata,t);
    end
end
%% Convert to ms
% isutc = strcmp(h5readatt(hdf5file,'/','Timezone'),'UTC');
% if isutc
%     vt = t*1000; % convert to ms
% else
%     vt = t; % already in datenum
% end
vt = t*1000; % convert to ms
