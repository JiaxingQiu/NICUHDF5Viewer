function [out3,out1,out2] = mypb6a(LB,UB,N,flagGUI)
%first trial of pb wavelet
%   [PSI,X] = MYPB(LB,UB,N) returns values of 
%   the wavelet on an N point regular grid 
%   in the interval [LB,UB].
%   Output arguments are the wavelet function PSI
%   computed on the grid X, and the grid X.
%
%   This wavelet has [-4 4] as effective support.
%
%   NO LONGER TRUE: Ideally N is 2+int*6

%   M. Mohr

sine1=sin(linspace(0,pi,N));
out2 = linspace(LB,UB,N);        % wavelet support.
len2=length(out2); %len2=length(out2)-2;
%p2=floor((len2)/2);
%p6=floor((len2)/6);
%p62=floor(p6/2);
%p64=floor(p6/4);
p62_34=floor((len2)/6/2/4*3);%p62*3/4
p62_14=floor((len2)/6/2/4);%p62*1/4
z=zeros(1,p62_34);%zeros
o=ones(1,p62_34);%ones
u=linspace(0,1,p62_14);%up
d=linspace(1,0,p62_14);%down
s=linspace(0.5,0,p62_14/2);%start
e=linspace(1,0.5,p62_14/2);%end
%out1=[zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62) zeros(1,p62) ones(1,p62)];
seg=[z u o d];
out1=[s seg seg seg seg seg z u o e];
len1=length(out1);
d1=len2-len1;
if d1>0
   d21=floor(d1/2);
   d22=ceil(d1/2);
   out1=[ones(1,d21)/2 out1 ones(1,d22)/2];
end
out1=(out1-0.5)*2;
out1(1)=0;
out1(end)=0; % OR out1(length(out2))=0;
out1=out1(1:length(out2));
out3=ones(1,length(out2));
out3(1)=0;
out3(end)=0;
out1=out1.*sine1;
out1=out1/((sum(out1.*double(out1>0))/length(out1)));%NORMALIZE

%%let WAVELET and matching PB (min=0 max=1) integrate to one
%out1=out1*2/(UB-LB);

end
