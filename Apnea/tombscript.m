fs=240;
CIfs=60;
gain=400;

[qt,qb,qgood,x,xt]=tombqrs(ecg,ecgt,gain,fs);
[p,pt,pgood]=tombstone(resp,respt,qt(qgood),qb(qgood),CIfs);
[tag,tagname,tag0]=wmtagevents(p,pgood,pt);
