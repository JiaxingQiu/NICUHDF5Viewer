function newgood=isolatedbad(x,good,dx)
%function newgood=isolatedbad(x,good,dx)
%
% x         input raw signal
% good      good points
% dx        tolerance for neighbors being good
%
% newgood  new good points

if ~exist('dx','var'),dx=.5;end

x=x(:);
n=length(x);
j1=1:(n-1);
left=[NaN;x(j1)];
leftgood=[0;good(j1)];
j2=2:n;
right=[x(j2);NaN];
rightgood=[good(j2);0];
newgood=good;
newgood=newgood|(leftgood&abs(x-left)<=dx);
newgood=newgood|(rightgood&abs(x-right)<=dx);
