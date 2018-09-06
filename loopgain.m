load('V:\Amanda\TestInputFiles\UVA\SIDS\2398\NICU_D29-1302667560_20110413_results.mat') % sids baby
% load('V:\Amanda\TestInputFiles\UVA\FilesKarenWants\NICU1_A2-1529416105_20180620_results.mat') % baby with a lot of periodic breathing

if sum(contains(result_name,'/Results/Apnea-III'))
    row = ismember(result_name,'/Results/Apnea-III');
elseif sum(contains(result_name,'/Results/Apnea-II'))
    row = ismember(result_name,'/Results/Apnea-II');
elseif sum(contains(result_name,'/Results/Apnea-I'))
    row = ismember(result_name,'/Results/Apnea-I');
else
    disp('No apnea results found. Closing loopgain.')
    return
end
    
notbreathing = result_data(row).data>0.5;
time = result_data(row).time;

starthour = 21;
hourstoshow = 2;
startsample = round(length(notbreathing)*starthour/24);
endsample = round(length(notbreathing)*hourstoshow/24)+startsample;
notbreathing=notbreathing(startsample:endsample);
time = time(startsample:endsample);

period = median(diff(time))/1000; % 0.25 sec
fs = 1/period; % 4 samples/sec
window = 5*60*fs; % 60 seconds/window * 4 samples/second = samples per window
numwindows = length(time)-window;

dr = zeros(numwindows,1);
lg = zeros(numwindows,1);
tlg = zeros(numwindows,1);

pbrow = strcmp(result_name,'/Results/PeriodicBreathing');
pbdata = result_data(pbrow).data;
pbtime = result_data(pbrow).time;

for w=1:numwindows
    wstart = w;
    wend = wstart+window;
    data = ~notbreathing(wstart:wend); % breathing data in window
    dr(w) = sum(data)/length(~isnan(data));
    lg(w) = 2*pi/(2*pi*dr(w)-sin(2*pi*dr(w)));
    tlg(w) = time(wstart+window/2);
end

ax1 = subplot(3,1,1);
% plot(utc2local(time/1000),notbreathing)
a = pbdata>0.6;
area(utc2local(pbtime/1000),a,'FaceColor','r')
hold on
area(utc2local(time/1000),notbreathing,'FaceColor','k','LineWidth',0.5)

ylabel('Apnea (Black), Periodic Breathing (Red)')
datetick('x')
xlim([min(utc2local(time/1000)),max(utc2local(time/1000))])
ylim([0 1.1])

ax2 = subplot(3,1,2);
plot(utc2local(tlg/1000),dr,'r')
ylabel('Duty Ratio')
datetick('x')
xlim([min(utc2local(time/1000)),max(utc2local(time/1000))])
ylim([0 1])

ax3 = subplot(3,1,3);
plot(utc2local(tlg/1000),lg,'b')
ylabel('Loop Gain')
xlim([min(utc2local(time/1000)),max(utc2local(time/1000))])
ylim([1 2])
datetick('x')
xlabel('Time of day (24:00)')

% ax4 = subplot(4,1,4);
% % plot(utc2local(pbtime/1000),pbdata,'b')
% hold on
% plot(utc2local(pbtime/1000),pbdata>0.6,'r')
% ylabel('Periodic Breathing')
% xlim([min(utc2local(pbtime/1000)),max(utc2local(pbtime/1000))])
% ylim([0 1])
% datetick('x')
% xlabel('Time of day (24:00)')

linkaxes([ax1,ax2,ax3],'x')