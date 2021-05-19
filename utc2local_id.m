function [d,dv,off]=utc2local_id(utc,id)
% utc is the time stamp in seconds (you will likely need to convert from ms for PreVent!)
% id is the PreVent ID
if id<2000 % CWRU
    [d,dv,off]=utc2localwrapper(utc,'ET');
elseif id<3000 % NU
    [d,dv,off]=utc2localwrapper(utc,'CT');
elseif id<4000 % UAB
    [d,dv,off]=utc2localwrapper(utc,'CT');
elseif id<5000 % UM
    [d,dv,off]=utc2localwrapper(utc,'ET');
elseif id<6000 % WUSTL
    [d,dv,off]=utc2localwrapper(utc,'CT');
end