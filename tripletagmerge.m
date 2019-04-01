function [result,t_temp,tag,tagcol] = tripletagmerge(tagcola,tagcolb,tagcolc,tagsa,tagsb,tagsc,thresh,info)

[~,~,ab,colab] = tagmerge(tagcola,tagcolb,tagsa,tagsb,thresh,info);
[~,~,bc,colbc] = tagmerge(tagcolb,tagcolc,tagsb,tagsc,thresh,info);
[~,~,ac,colac] = tagmerge(tagcola,tagcolc,tagsa,tagsc,thresh,info); 
tagsab.tagtable = ab;
tagsbc.tagtable = bc;
tagsac.tagtable = ac;
tagcolab.tagname = colab;
tagcolbc.tagname = colbc;
tagcolac.tagname = colac;
[~,~,abbc,colabbc] = tagmerge(tagcolab,tagcolbc,tagsab,tagsbc,thresh,info);
tagsabbc.tagtable = abbc;
tagcolabbc.tagname = colabbc;
[result,t_temp,tag,tagcol] = tagmerge(tagcolabbc,tagcolac,tagsabbc,tagsac,thresh,info);