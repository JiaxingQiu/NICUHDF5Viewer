function [pb_indx,pb_time,scale,unTomb,Ttime] = Calc_pb_wavelet(unTomb,Ttime)
%unTomb is unprocessed tombstone signal
%Ttime is time for unprocessed tombstone

first_scale=240;
scale_step=12;%24;
last_scale=960;

coeffs1 = cwt5(unTomb,first_scale:scale_step:last_scale,'mypb6a');
%coeffs=max(coeffs1,coeffs2);
[pb_indx1,pb_time1,scale1]=analyze_wavelet_coeffs(coeffs1,Ttime,first_scale,scale_step);
clear coeffs1
coeffs2 = cwt5(unTomb,first_scale:scale_step:last_scale,'mypb6b');
[pb_indx2,pb_time2,scale2]=analyze_wavelet_coeffs(coeffs2,Ttime,first_scale,scale_step);
clear coeffs2

pbmat=[pb_indx1;pb_indx2];
scalemat=[scale1;scale2];
pbtimemat=[pb_time1;pb_time2];
[pb_indx, ind]=max(pbmat);
for n=1:length(ind)
scale(n)=scalemat(ind(n),n);
pb_time(n)=pbtimemat(ind(n),n);
end
%          pb_indx_out=[pb_indx_out, pb_indx];
%          pb_time_out=[pb_time_out, pb_time];
%          unTomb_out=[unTomb_out; unTomb];
%          Ttime_out=[Ttime_out, Ttime];
%          scale_out=[scale_out, scale];
%          %end
%          pb_indx=pb_indx_out;
%          pb_time=pb_time_out;
%          unTomb=unTomb_out;
%          Ttime=Ttime_out;
%          scale=scale_out;

end

function [maxc,timemaxc,cycLEN]=analyze_wavelet_coeffs(coeffs,time,first_scale,scale_step)
    [rowlen, collen]=size(coeffs);
    for n=1:floor((collen-160)/80) %divide into windows
        cofseg=coeffs(:,n*80-79:n*80+80); %20 sec window
        cofseg=abs(cofseg);
        [C1, I1]=max(cofseg);
        [C2, I2]=max(C1);
        scale=I1(I2);
        %maxc(n)=max(max(cofseg));
        maxc(n)=C2;
        cycLEN(n)=scale*scale_step+first_scale-scale_step;
        timemaxc(n)=time(n*80);
        %maxc(n)=max(coeffs(:,n));
    end
end