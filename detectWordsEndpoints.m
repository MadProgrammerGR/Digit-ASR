function [startSamples,endSamples] = detectWordsEndpoints(x,Fs,L,R,shouldPlot)

%% Calculate logarithmic energy and zero crossing rate for every frame
window = hamming(L);
totalFrames = ceil((length(x)-L+1)/R);
energy = zeros(1,totalFrames);
zerocrossings = zeros(1,totalFrames);
for i = 0:totalFrames-1 %(ss+L-1 <= totalFrames)
    frame = x(i*R+1:i*R+L).*window;
    energy(i+1) = 10*log10(sum(frame.^2));
    zerocrossings(i+1) = sum(abs(diff(sign(frame))));
end
energy = energy - max(energy);
zerocrossings = zerocrossings*R/(2*L); % normalized (per 10 msec) zero crossings contour for utterance
zerocrossings = smoothingFilter(zerocrossings,false,Fs);

%% Calculate average and standard deviation 
% of energy and zerocrossing for background signal
trainingDuration = 100; % first 100 milliseconds
trainingFrames = trainingDuration*Fs/(1000*R);
eavg=mean(energy(1:trainingFrames));
esig=std(energy(1:trainingFrames));
zcavg=mean(zerocrossings(1:trainingFrames));
zcsig=std(zerocrossings(1:trainingFrames));

%% Calculate Detection Parameters
IF = 35;                       %% Constant Zero Crossing Threshold         
IZCT = max(IF,zcavg+3*zcsig);  %% Variable Zero Crossing Threshold

IMX = max(energy);              %% Max Log Energy
ITU = IMX-20;                   %% High Log Energy Threshold
ITL = min(ITU, max(eavg+3*esig, ITU-10)); %% Low Log Energy Threshold

minTimeBetween = 500; % minimum milliseconds between words
minFramesBetween = (minTimeBetween/1000)*Fs/R; % minimum # of frames between words


%% Calculate cuts between words
idx = find(energy>=ITU);
cuts = [];
% loop each frame with energy above ITU
prevFrame = Inf;
for i = 1:length(idx)-1
    % check if next few frames (3) are all above ITU
    if idx(i)+3 <= length(energy) && all(energy(idx(i):idx(i)+3)>=ITU)
        if idx(i) - prevFrame >= minFramesBetween
            cuts(end+1) = floor((idx(i) + prevFrame)/2);
        end
        prevFrame = idx(i);
    end
end
cuts = [1 cuts totalFrames];

%% Use endpoints function to narrow the cut pairs
startSamples = [];
endSamples = [];
for i = 1:length(cuts)-1
    wordEnergy = energy(cuts(i):cuts(i+1));
    wordZCross = zerocrossings(cuts(i):cuts(i+1));
    [B,E] = endpoints(wordEnergy,wordZCross,ITU,ITL,IZCT);
    startSamples(end+1) = B+cuts(i)-1;
    endSamples(end+1) = E+cuts(i)-1;
end
% convert from frame indexes to sample indexes
startSamples = (startSamples-1)*R+1;
endSamples = (endSamples-1)*R+L;


%% plots
if exist("shouldPlot","var") && shouldPlot
    figure;
    subplot(3,1,1);
    t = (0:length(x)-1)/Fs;
    plot(t,x);
    maxAmpl=max(abs(x));
    ylim([-abs(maxAmpl) abs(maxAmpl)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(['Speech Signal with Endpoints of each Word']);
    grid on; hold on;
    for i = 1:length(startSamples)
        % convert from samples to time
        h1 = xline(startSamples(i)/Fs,'r');
        xline(endSamples(i)/Fs,'r');
    end
    for i = 1:length(cuts)
        % convert from frame index to time
        h2 = xline(((cuts(i)-1)*R+1)/Fs,'k--');
    end
    legend([h1 h2],'endpoints','cuts');
    
    subplot(3,1,2);
    plot(energy);
    yline(ITU,'g');
    yline(ITL,'g');
    xlabel('Frame');
    ylabel('Energy');
    title(['Logarimthmic Energy of Each Frame and Thresholds']);
    grid on; hold on;
    for i = 1:length(startSamples)
        % convert back from samples index to frame index
        h1 = xline((startSamples(i)-1)/R+1,'r');
        xline((endSamples(i)-L)/R+1,'r');
    end
    for i = 1:length(cuts)
        h2 = xline(cuts(i),'k--');
    end
    legend([h1 h2],'endpoints','cuts');

    subplot(3,1,3);
    stem(zerocrossings);
    yline(IZCT,'g');
    xlabel('Frame');
    ylabel('Zerocrossings');
    title(['Zerocrossings of Each Frame of speech signal and Threshold']);
    grid on; hold on;
    for i = 1:length(startSamples)
        % convert back from samples index to frame index
        h1 = xline((startSamples(i)-1)/R+1,'r');
        xline((endSamples(i)-L)/R+1,'r');
    end
    for i = 1:length(cuts)
        h2 = xline(cuts(i),'k--');
    end
    legend([h1 h2],'endpoints','cuts');
    pause;
end
