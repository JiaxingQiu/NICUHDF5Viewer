function flatness = isflat(data,fs,duration)
window = round(duration*fs); % Look for 2 seconds of flat signal
points = length(data);
flatness = zeros(points,1);
% for i=1:points
%     if i+window>points
%         endpoint=points;
%     else
%         endpoint=i+window;
%     end
%     isflat=all(data(i:endpoint)==data(i));
%     if isflat
%         flatness(i:endpoint)=isflat;
%     end
% end

%Find when data is same as previous point
diffx=[1;diff(data)];
same=diffx==0;

%Find events when data same for 
[start,stop]=threshcross(same,1,window-1,0);

if isempty(start),return,end
%Include first point
start=start-1;
