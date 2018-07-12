function [y,yt,yna,ynew]=naninterp(x,xt,yt,extrap)
%function [y,yt,yna,ynew]=naninterp(x,xt,yt,extrap)
%
% x input signal
% xt input timestamps
% yt desired timestamps
% extrap flag to extrap (default=0 no extrapolation)

% y interpolated signal
% yt desired timestamps
% yna not a numbers (NaN)
% ynew new values

if ~exist('extrap','var'),extrap=0;end
nx=length(x);
if ~exist('xt','var'),xt=(1:nx)';end
if ~exist('yt','var'),yt=xt;end
ny=length(yt);
y=NaN*ones(ny,1);
ynew=true(ny,1);
%Find common timestamps
[~,jx,jy]=intersect(xt,yt);
y(jy)=x(jx);
ynew(jy)=false;

yna=isnan(y);
%Get rid on NaNs from input signal
xna=isnan(x);
x=x(~xna);
xt=xt(~xna);
%Interpolate for NaN
y(yna)=interp1(xt,x,yt(yna),'linear');

%Extrapolate for any more NaNs
if extrap>0
    y(isnan(y))=interp1(xt,x,yt(isnan(y)),'nearest','extrap');
end

