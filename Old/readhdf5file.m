function readhdf5file(hObject,eventdata,handles)
info = h5info(fullfile(handles.pathname, handles.filename));
datasetnames = {};
numsigs = 0;
handles.TimeGroup = 0;
for i=1:length(info.Groups)
    if strcmp(info.Groups(i).Name,'/VitalSigns')
        handles.VSGroupNum = i;
    elseif strcmp(info.Groups(i).Name,'/Waveforms')
        handles.WFGroupNum = i;
    end
    for j=1:length(info.Groups(i).Groups) % There are no datasets directly under '/Times', so we don't go here for '/Times'
        if ~strcmp(info.Groups(i).Name,'/Events')
            numsigs = numsigs+1;
            datasetnames{numsigs,1} = char([info.Groups(i).Groups(j).Name]);    
        end
    end
    if strcmp(info.Groups(i).Name,'/Times')
        handles.TimeGroup = 1; % This indicates that the times are saved as a separate mega-group
    end
end
handles.alldatasetnames = datasetnames;
usefulfields = ["HR","SPO2-%","SPO2-R","Waveforms/I","Waveforms/II","Waveforms/III","Waveforms/RR","Waveforms/SPO2"];
usefulfieldindices = contains(datasetnames,usefulfields);
handles.usefuldatasetnames = datasetnames(usefulfieldindices);
for i=1:length(handles.usefuldatasetnames)
    set(handles.listbox_avail_signals,'string',handles.usefuldatasetnames);
end
% Update handles structure
guidata(hObject, handles);