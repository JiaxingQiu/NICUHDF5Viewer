function [j1,j2,start,stop]=tagjoin(start,stop,gap)
%function [start,stop]=tagjoin(start,stop,gap)
%
% start = start for tag
% stop = stop for tag
% gap = gap between tags to join
%
% j1 = new start indice for tag
% j2 = new stop indice for tag
% start = new start for tag
% stop = new stop for tag

nt=length(start);
j1=(1:nt)';
j2=j1;
if nt<2,return,end
tgap=start(2:nt)-stop(1:(nt-1));
j1=1;
j2=nt;
j=find(tgap>gap);
if ~isempty(j)
    j1=[1;(j+1)];
    j2=[j;nt];
end
start=start(j1);
stop=stop(j2);
