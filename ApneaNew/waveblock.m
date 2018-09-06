function [y,yt,yna,ynew,start,fs]=waveblock(x,xt,fs,yt,extrap)
%function [y,yt,yna,ynew]=waveblock(x,xt,yt,extrap)
%
% x input signal
% xt input timestamps
% fs frequency of signal (default=1)
% window vector with start and stop point

% extrap flag to extrap (default=1 extrapolation)

% y  block of consecutive data 
% yt timestamps in seconds
% yna not a numbers (NaN)
% ynew new values
% start  timestamp of start of block in seconds

nx=length(x);
if ~exist('xt','var'),xt=(1:nx)';end
if ~exist('fs'),fs=1;end
if ~exist('yt'),yt=[];end
%if isempty(start),start=xt(1);end
if ~exist('extrap','var'),extrap=1;end

nt=length(xt);
block=nx/nt;

%if isempty(stop),stop=xt(end);end

%Convert times to sample number
[xs,start]=samplenumber(xt,fs,block);

if isempty(yt)
    ys=(min(xs):max(xs))';
else
    ys=round((yt-start)*fs);
    ys=unique(ys);
end

ny=length(ys);
nx=length(x);
y=NaN*ones(ny,1);
ynew=true(ny,1);
%Find common timestamps
[~,jx,jy]=intersect(xs,ys);
y(jy)=x(jx);
ynew(jy)=false;

yna=isnan(y);
%Get rid on NaNs from input signal
xna=isnan(x);
x=x(~xna);
xs=xs(~xna);
%Interpolate for NaN
y(yna)=interp1(xs,x,ys(yna),'linear');

%Extrapolate for any more NaNs
if extrap>0
    y(isnan(y))=interp1(xs,x,ys(isnan(y)),'nearest','extrap');
end
yt=start+ys/fs;
