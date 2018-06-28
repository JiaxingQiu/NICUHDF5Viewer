function [f,P1] = plotAmandafft(sig,inputtime)
% sig = the signal you want to take the fft of
% inputtime = the time vector of that signal

sig = fillmissing(sig,'previous'); % fill in any nans in the middle of the file
sig = sig(~isnan(sig)); % any nans at the beginning or end of the file will be removed
sig = sig - movmean(sig,50);
isodd = mod(length(sig),2);
if isodd
    sig = sig(1:end-1);
end

T = median(diff(inputtime))/1000;   % Sampling Period
Fs = 1/T;                           % Sampling frequency                    
L = length(sig);                    % Length of signal
t = (0:L-1)*T;                      % Time vector

Y = fft(sig);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
