function [tag,tagname]=dataavailabletags(x,xt,T,pmin,tmin,negthresh,bd2)
% function [tag,tagname]=dataavailabletags(x,xt,T,pmin,tmin)
%
% x = input signal with 1s for data, 0s for missing data and 2's for split points
% xt = input signal timestamps
% T = threshold for event
% pmin = minimum number of points below threshold (default one)
% tmin = time gap between crossings to join (default zero)
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

% Get rid of missing data
j=find(isnan(x));
x(j)=[];
xt(j)=[];
if isempty(x),return,end

if ~exist('tmin','var'),tmin=0;end
if ~exist('pmin','var'),pmin=1;end
if ~exist('negthresh','var'),negthresh=1;end

% Find crossing events with minimum number of points
[i1,i2]=threshcross(x,0.5,pmin,0); % we use threshcross here instead of threshcross2 because time gaps are already accounted for in this code

bd2(~logical(x))=0; % Don't tag nan values at the edge of missing data, because they were already flagged. This just creates extra edges.
i3 = find(bd2);
repeat = ismember(i3,i2);
i3 = i3(~repeat);
i4 = i3+1;

j1 = unique([i1;i4]);
j2 = unique([i2;i3]);

if isempty(j1),return,end

tsamp = median(diff(xt));

t1 = xt(j1);
t2 = xt(j2);

ne=length(t1);

dur=t2-t1+tsamp;
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
    if negthresh
        np(i)=sum(xx<=T);
    else
        np(i)=sum(xx>=T);
    end
end
tag=[t1 t2 dur np area extrema];
