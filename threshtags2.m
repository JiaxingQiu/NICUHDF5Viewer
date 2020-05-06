function [tag,tagname]=threshtags2(x,xt,T,pmin,tmin,negthresh,lessequal)
% This function has been edited to call threshcross2, which is able to
% identify gaps in time even if no nans are present
% It also changes the threshold to < instead of <=. This allows for a
% proper calculation of area (instead of the area below 79.99, it can
% calculate the area under 80 for example).

% function [tag,tagname]=threshtags2(x,xt,T,pmin,tmin)
%
% x = input signal
% xt = input signal timestamps
% T = threshold for event
% pmin = minimum number of points below threshold (default one)
% tmin = time gap between crossings to join (default zero)
% lessequal = set to 1 for < or >. Set to 2 for <= or >=.
%
% tag = tag times and info
% tagname = name of tagput data
% negthresh = 1 if you want to identify events that drop below a threshold
% negthresh = 0 if you want to identify events above a threshold
% tsamp = duration of each point (ex. 2 sec for UVA in seconds, 1000 ms for WashU in ms)

tagname=cell(6,1);
tagname{1}='Start';
tagname{2}='Stop';
tagname{3}='Duration';
tagname{4}='Number points';
tagname{5}='Area';
tagname{6}='Minimum';
tag=zeros(0,length(tagname));

% Remove duplicate timestamps. Only keep the x value relating to the last
% copy of a given timestamp;
[xt,ia] = unique(xt,'last');
x = x(ia);

% Get rid of missing data
j=find(isnan(x));
x(j)=[];
xt(j)=[];
if isempty(x),return,end

if ~exist('tmin','var'),tmin=0;end
if ~exist('pmin','var'),pmin=1;end
if ~exist('negthresh','var'),negthresh=1;end

% if length(tmin)>1
%     tmin=tmin(1);
%     gmin=tmin(2);
% else
%     gmin=0;
% end   
% if length(pmin)>1
%     pmin=pmin(1);    
%     dmin=pmin(2);
% else
%     dmin=0;
% end

% Find crossing events with minimum number of points
[i1,i2]=threshcross2(x,xt,T,pmin,negthresh,lessequal);
if isempty(i1),return,end

t1=xt(i1);
t2=xt(i2);
%Get rid of crossing events less than minimum time duration
% if dmin>2
%     dur=t2-t1+2;    
%     j=dur<dmin;
%     i1(j)=[];
%     i2(j)=[];
% end

tsamp = median(diff(xt));

%Join events with minimum time gap
if tmin>0
    [k1,k2]=tagjoin(t1,t2,tmin);   
    j1=i1(k1);
    j2=i2(k2);
else
    j1=i1;
    j2=i2;
end    
t1=xt(j1);
t2=xt(j2);
ne=length(j1);

dur=t2-t1+tsamp;
%np=j2-j1+1;
np=zeros(ne,1);
area=zeros(ne,1);
extrema=NaN*ones(ne,1);
for i=1:ne
    j=(j1(i):j2(i))';
    xx=x(j);
    if negthresh
        extrema(i)=min(xx);
    else
        extrema(i)=max(xx);
    end
    if extrema(i)<1
        extrema(i) = round(extrema(i),2);
    end
    aa=max(T+1-xx,0);
    area(i)=sum(aa);
    if lessequal==1
        if negthresh
            np(i)=sum(xx<T);
        else
            np(i)=sum(xx>T);
        end
    else
        if negthresh
            np(i)=sum(xx<=T);
        else
            np(i)=sum(xx>=T);
        end
    end
end
tag=[t1 t2 dur np area extrema];
