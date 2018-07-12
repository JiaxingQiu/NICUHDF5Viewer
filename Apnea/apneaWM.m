function [ecgI,ecgII,ecgIII,wt,gain,fs,CIfs] = apneaWM(filename)
ecgI = [];
ecgII = [];
ecgIII = [];

[wdata,wname,wt,info]=gethdf5wave(filename);
gain = 
fs = 

dataindexI = ismember(wname,'/Waveforms/I');
[tag,tagname,tag0] = runWMalgs(dataindexI,wdata,gain,fs)

dataindexII = ismember(wname,'/Waveforms/II');
[tag,tagname,tag0] = runWMalgs(dataindexII,wdata,gain,fs)

dataindexIII = ismember(wname,'/Waveforms/III');
[tag,tagname,tag0] = runWMalgs(dataindexIII,wdata,gain,fs)

end

function [tag,tagname,tag0] = runWMalgs(dataindex,wdata,gain,fs)
    if ~isempty(dataindex)
        ecg = wdata(:,dataindex);
        [qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt,gain,fs);
        [p,pt,pgood]=tombstone(resp,respt,qt(qgood),qb(qgood),CIfs);
        [tag,tagname,tag0]=wmtagevents(p,pgood,pt);
    else
        tag = [];
        tagname = [];
        tag0 = [];
    end
end