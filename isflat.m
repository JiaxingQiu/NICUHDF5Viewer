function flatness = isflat(data,fs)
window = 5*fs; % Look for 5 seconds of flat signal
points = length(data);
flatness = zeros(points,1);
for i=1:points
    if i+window>points
        endpoint=points;
    else
        endpoint=i+window;
    end
    isflat=all(data(i:endpoint)==data(i));
    if isflat
        flatness(i:endpoint)=isflat;
    end
end