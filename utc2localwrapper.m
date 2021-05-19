function [d,dv,off] = utc2localwrapper(utc, tz, method)

% utc2local converts to Eastern time zone and accounts for the daylight
% savings time at the date of collection - therefore we just need to
% account for the time zone because daylight savings time has already been
% taken into account

if ~exist('method','var')
    method=0;
end

[d,dv,off]=utc2local(utc,method);

if strcmp(tz,'CDT')
    dv(:,4)=dv(:,4)-1;
    d=datenum(dv);
elseif strcmp(tz,'CST')
    dv(:,4)=dv(:,4)-1;
    d=datenum(dv);
elseif strcmp(tz,'CT')
    dv(:,4)=dv(:,4)-1;
    d=datenum(dv);
elseif strcmp(tz,'MDT')
    dv(:,4)=dv(:,4)-2;
    d=datenum(dv);
elseif strcmp(tz,'MST')
    dv(:,4)=dv(:,4)-2;
    d=datenum(dv);
elseif strcmp(tz,'MT')
    dv(:,4)=dv(:,4)-2;
    d=datenum(dv);
elseif strcmp(tz,'PDT')
    dv(:,4)=dv(:,4)-3;
    d=datenum(dv);
elseif strcmp(tz,'PST')
    dv(:,4)=dv(:,4)-3;
    d=datenum(dv);
elseif strcmp(tz,'PT')
    dv(:,4)=dv(:,4)-3;
    d=datenum(dv);
end

