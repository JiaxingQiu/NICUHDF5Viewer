function [vdata,vlabel,vtout]=getWUSTLvital2(values,vtin,vlabel)
%vdata - matrix/structure with vital sign values
%vlabel - vital sign names for columns of the matrix
%vtout - time stamps for row of the matrix

roundedtime = datenum_round_off(vtin,'second');
vtout = (roundedtime(1):datenum(seconds(1)):roundedtime(end))';
[~, loc] = ismember(datevec(roundedtime),datevec(vtout),'rows');
columns = size(values,2);
vdata = ones(length(vtout),columns)*nan;
vdata(loc(loc~=0),:) = values(loc~=0,:);
vdata(vdata==8388607) = nan;
