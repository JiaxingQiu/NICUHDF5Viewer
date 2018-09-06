function [err]=pb_tag_wavelet(n)
 % this is only for adding max coeff because it wasn't added originally
%connect to postgresql
CWD=pwd;
cd /sciclone/home04/mmohr/psqlQs
Connect_To_PSQL_securely
cd(CWD)

% Create the database connection (port 5432 is the default postgres chooses
% on installation)
driver=org.postgresql.Driver;
url = 'jdbc:postgresql://tw00.sciclone.wm.edu:5432/nb14';
conn=driver.connect(url, props);

%load('32wksfiles','files')
%load('filesnot32wks','files')
%load pb2tag
%load('missing_files')
%files=pb2tag;
%load('not_PBtags')
%load('PBmissing')
load('all_NB_files.mat')

D={'NICU_A1';'NICU_A2';'NICU_A3';'NICU_A4';'NICU_A5';'NICU_A6';'NICU_B10';'NICU_B11';'NICU_B12';'NICU_B13';'NICU_B14';'NICU_B7';'NICU_B8';'NICU_B9';'NICU_C15';'NICU_C16';'NICU_C17';'NICU_C18';'NICU_C19';'NICU_C20';'NICU_D21';'NICU_D22';'NICU_D23';'NICU_D24';'NICU_D25';'NICU_D26';'NICU_D27';'NICU_D28';'NICU_D29';'NICU_E30';'NICU_E31';'NICU_E32';'NICU_E33';'NICU_E34';'NICU_E35';'NICU_F36';'NICU_F37';'NICU_F38';'NICU_F39';'NICU_F40';'NICU_G41';'NICU_G42';'NICU_G43';'NICU_G44';'NICU_G45'};
for d=1:length(D)
addpath(['/sciclone/data20/NewBaby/Batches/pb_indx/' D{d}]);
end

nBatch=1000;
for m=(n-1)*nBatch+1:n*nBatch
    if m>=1 && m<=length(files);
       if exist([files{m} '_pb_wavelet_indx.mat'])==2;
            [err] = pb_tag(files{m}, conn);
       end
    end
end
end

function [err]=pb_tag(filename,conn)
%Periodic breathing if the index is greater than 5. If the gap is less than
%or equal to 60 seconds events are combined.
pb_filename=[filename '_pb_wavelet_indx.mat'];
load(pb_filename)
%pb_time=pb_timestamp;
%pb_indx=pb_signal;
m=0;
tag=0;
pb_start_time=[];
pb_end_time=[];
%Go through the whole pb_indx vector.
%Periodic breathing if index is greater than or equal to thresh.
%Give start time and end time for each pb episode.

%thresh=0.5;
thresh=0.6
for n=1:length(pb_time)
    if tag==0 & pb_indx(n) >=thresh
        m=m+1;
        pb_start_time(m)=pb_time(n);%-30;
        tag=1;
    end
    
    if tag==1 & pb_indx(n) <thresh
        pb_end_time(m)=pb_time(n-1);%+30;
        tag=0;
    end
        
end


%If the last data point was pb then end time is the last time value.
%(!This might need to be fixed for other end times past the end of the file, since 30 seconds is greater than the time step of 10sec!)
%it is fixed in theis version
if tag==1
    pb_end_time(m)=pb_time(end);
end
err=0;
if m==0
    %long_pb_start_time=[];
    %long_pb_end_time=[];
    %disp(filename)
else
    %if m>=length(pb_end_time)
    %    m=length(pb_end_time);
    %end
    if pb_end_time(m)>pb_time(end)
    pb_end_time(m)=pb_time(end);
end
long_pb_start_time=[];
long_pb_end_time=[];
if ~isempty(pb_start_time)
for k=1:length(pb_start_time)-1
    gap(k)=pb_start_time(k+1)-pb_end_time(k);
end
p=1;
long_pb_start_time(1)=pb_start_time(1);
for n=1:length(pb_start_time)-1
    %as long as the gap is less than or equal to 60 move on
    %if gap(n) <=60
    %  long_pb_end_time(p)=pb_end_time(n+1);
    %else
      long_pb_end_time(p)=pb_end_time(n);
      p=p+1;
      long_pb_start_time(p)=pb_start_time(n+1);
    %end
end
len1=length(long_pb_start_time);
len2=length(long_pb_end_time);
if len1>len2
    long_pb_end_time(len1)=pb_end_time(end);
end
end
%add tags to database
file_ind=find(filename=='-',1,'first');
BedID=filename(1:file_ind-1);
for nm=1:length(long_pb_start_time)
PB_time1 = Doug_time_integer_to_date_string(long_pb_start_time(nm));
PB_time2 = Doug_time_integer_to_date_string(long_pb_end_time(nm));
freqs=scale(pb_time>=long_pb_start_time(nm) & pb_time<=long_pb_end_time(nm));
maxcoeff=max(pb_indx(pb_time>=long_pb_start_time(nm) & pb_time<=long_pb_end_time(nm)));
pbfreq=round(median(freqs));
[bednum]=bedid2bednum(BedID);
sql=['select * from pb_tags where bednum=''' num2str(bednum) ''' and start_time=''' PB_time1 ''' and end_time=''' PB_time2 ''''];
        ps=conn.prepareStatement(sql);
        rs=ps.executeQuery();
        % Read the results into an array of result structs
        count=0;

        %find the number of columns
        rsmd=rs.getMetaData();
        numberOfColumns=rsmd.getColumnCount();
        result=cell(1,numberOfColumns);
        while rs.next()
            count=count+1;
            for n=1:numberOfColumns
            result{count,n}=char(rs.getString(n)); %you could also use getInt, getFloat, or getDouble
            end
        end  
        isempty(result{1})
if ~isempty(result{1})

       sql=['UPDATE pb_Tags SET max_coeff = ' num2str(maxcoeff) ' WHERE bednum=''' num2str(bednum) ''' and start_time=''' PB_time1 ''' and end_time=''' PB_time2 '''']
    ps=conn.prepareStatement(sql);
        rs=ps.executeUpdate();
end

end
end
%             sql=['select filename from pb_files_tagged where filename=''' filename ''''];
%                 ps=conn.prepareStatement(sql);
%                 rs=ps.executeQuery();
%             result={};
%         while rs.next()
%             result=char(rs.getString(n)); %you could also use getInt, getFloat, or getDouble
%         end  
%         if isempty(result)
%             sql=['insert into pb_files_tagged (filename) VALUES (''' filename ''')'];
%                 ps=conn.prepareStatement(sql);
%                 rs=ps.executeUpdate();
%         end
end

function [bednum]=bedid2bednum(bedid)
bednum=str2num(bedid(find(bedid=='_')+2:end));
end

function date_string = Doug_time_integer_to_date_string(local_time,varargin)
real_time = local_time/(24*3600)+datenum('1000-01-01 00:00:00');
if(isempty(varargin))
    format=31;
else
    format = varargin{1};
end
date_string = datestr(real_time, format);
end