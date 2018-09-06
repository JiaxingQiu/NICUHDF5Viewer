
load('input_sample_for_doug.mat');


unTomb = double(aprobU)/1000;
Ttime = double(T_aprobU)/240;
[pb_indx,pb_time,scale,unTomb,Ttime] = Calc_pb_wavelet(unTomb,Ttime);

figure;hold on;
plot(pb_time,pb_indx)
plot(Ttime,unTomb+2)
hold off;