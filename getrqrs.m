function qt = getrqrs(handles)
qt = [];

if strcmp(handles.info.fixedname(handles.dataindex),'ECGIII')
    lead = 3;
elseif strcmp(handles.info.fixedname(handles.dataindex),'ECGII')
    lead = 2;
elseif strcmp(handles.info.fixedname(handles.dataindex),'ECGI')
    lead = 1;
else
    return;
end

if isempty(handles.rqrs(lead).qrs)
    return;
end

qt = handles.rqrs(lead).qrs.qt;

if handles.tstampchoice==1 % convert from utc date in seconds to days since time zero
    qt = qt*1000-double(handles.info.timezero); % puts UTC date (ms) into ms since time zero
    qt = qt/86400/1000; % convert to days since time zero
elseif handles.tstampchoice==2
    qt = utc2local(qt); % convert from utc date in seconds to matlab date
end