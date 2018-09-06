load_path = 'C:\Users\hqtruong\Desktop\sample_mat_files\';
load_name = 'hs_apnea_Bed01_Day0042.mat';
load_dir = [load_path,load_name];
load_vars = {'T_aprobU','aprobU'};
load(load_dir,load_vars{:})

unTomb = double(aprobU)/1000;
Ttime = double(T_aprobU)/240;
[pb_indx,pb_time,scale,unTomb,Ttime] = Calc_pb_wavelet(unTomb,Ttime);

figure;hold on;
plot(pb_time,pb_indx)
plot(Ttime,unTomb+2)
hold off;