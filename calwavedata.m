function [y,cal,fac]=calwavedata(x,file,dataset)
%function y=calwavedata(x,file,name)
%
%x         uncallibrated data
%file      hdf5 file
%datset    name of dataset with calibration info
%
%y         callibrated data
%cal       4 parameter calibration vector
%fac       2 parameter scaling factor

x=double(x);
y=x;
cal=[];
fac=[];

%Convert scaling factor to calibration vector used for BedMaster data
%Cal = “Cal Lo, Cal Hi, Grid Lo, Grid Hi”
% The Cal and Grid values are used in a couple of scaling tags as well:
%Scale = (Cal Hi – Cal Lo) / (Grid Hi – Grid Lo)
%Scaled_data = Cal Lo + (Raw Sample – Grid Lo) * Scale *-1
%If Cal Hi is NaN then Scale = -0.025

dgroup=[dataset,'/data'];
try
    cal=h5readatt(file,dgroup,'Cal');
end
if isempty(cal)
    try
        cal=h5readatt(file,dataset,'Cal');
    end
end   
%Convert calibration to numbers if necessary
if iscell(cal)
    cal=cal{1};
end
if ischar(cal)
    try
        cal=cell2mat(textscan(cal,'%f','Delimiter',','));
    end
end
fac=[];
if ~isempty(cal)
    if length(cal)>=4
        fac(2)=-(cal(2)-cal(1))/(cal(4)-cal(3));
        fac(1)=cal(1)-fac(2)*cal(3);
    end
end
if length(fac)>1
    y=fac(2)*x+fac(1);
end
