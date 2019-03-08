function [vdata,vname,vt,info]=gethdf5vital(hdf5file,vname,vformat)
%
%hdf5file - HDF5 file with vital sign data
%vname - name of vital signs to retrieve ... 0 or empty => all (default);
%vformat - format of output 
%          0=> matrix and time stamps (default)
%          1=> long matrix with vital sign number, and value
%          2=> structure 
%
%vdata - matrix/structure with vital sign values
%vname - vital sign names for columns of the matrix
%vt - time stamps for row of the matrix for vformat=0
%info - information about entire HDF5 file

if ~exist('vname','var'),vname='/VitalSigns';end
if ~exist('vformat','var'),vformat=0;end

% allvital=isempty(vname);
[data,~,info]=gethdf5data(hdf5file,vname);
[vdata,t,vname]=vdataformat(data,vformat);
vt = t*1000; % convert to ms

