function [y,yt,yna,ynew]=nogaps(x,xt,fs)
%function [y,yt,yna,ynew]=nogaps(x,xt,fs)
%
% x    input signal
% xt   input timestamps
% fs   sampling frequency resolution

% y    new signal
% yt   desired timestamps
% yna  original not a numbers (NaN)
% ynew new values

if ~exist('fs','var'),fs=1;end

%Convert times to sample number for interpolation
xs=round(xt*fs);
ys=(min(xs):max(xs))';
yt=ys/fs;

ny=length(ys);
y=NaN*ones(ny,1);
ynew=true(ny,1);

%Find common timestamps
[~,jx,jy]=intersect(xs,ys);
y(jy)=x(jx);
ynew(jy)=false;
yna=isnan(y);
if sum(yna)==0,return,end

%Get rid on NaNs from input signal
xna=isnan(x);
x=x(~xna);
xt=xt(~xna);

%Interpolate for NaN
y(yna)=interp1(xs,x,ys(yna),'linear');
