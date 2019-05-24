function [digitsLabels] = digitsASR(filename,refSet,shouldPlot)
[x, FsOrig] = audioread(filename);
x = x/max(max(x),-min(x));
Fs = 8000;
x = resample(x, Fs, FsOrig);

%% highpass filtering 
% Band reject 0-100Hz
% Band transition 100-200Hz
% Bandpass 100-4000Hz
hpforder = 30;              %% order of highpass filter  
lowcut = 100;               %% low band reject frequency   (Hz)
highcut = 200;              %% high band cut-off frequency (Hz)
hpfilter = firpm(hpforder,[0 lowcut highcut Fs/2]/(Fs/2),[0 0 1 1]);
x = filter(hpfilter,1,x);

%% word detection
frameDuration = 30;         %% Frame Duration in ms
L = frameDuration*Fs/1000;  %% Frame Duration in samples
frameShift = 10;            %% Frame Shift in ms
R = frameShift*Fs/1000;     %% Frame Shift in samples
[startSamples,endSamples] = detectWordsEndpoints(x,Fs,L,R,shouldPlot);
numWords = length(startSamples);

%% play each extracted word and pause in between
if exist("shouldPlot","var") && shouldPlot
    for i = 1:numWords
        fprintf("Playing extracted word (%d/%d)\n",i,numWords);
        wordSegment = x(startSamples(i):endSamples(i));
        soundsc(wordSegment,Fs);
        pause;
    end
end

digitsLabels = cell(1,numWords);
for i = 1:numWords
    wordSegment = x(startSamples(i):endSamples(i));
    [coeffs,delta,deltaDelta] = normalizedMFCC(wordSegment,Fs,L,R,shouldPlot);
    %% calculate DTW distances to each reference coeffs
    dists = zeros(1,length(refSet));
    for r = 1:length(refSet)
        dists(r) = dtw(coeffs,refSet(r).coeffs,'squared');
%         dists(r) = dtw(coeffs,refSet(r).coeffs,'squared')...
%             + dtw(delta,refSet(r).delta,'squared')...
%             + dtw(deltaDelta,refSet(r).deltaDelta,'squared');
    end
    
    %% calculate KNN
    labels = {'O','Z','1','2','3','4','5','6','7','8','9'};
    counts = zeros(1,length(labels));
    K = 5;
    [~,Idx] = sort(dists);
    for nn = Idx(1:K)
        labelIndex = find(strcmp(labels,refSet(nn).label));
        counts(labelIndex) = counts(labelIndex) + 1;
    end
    % best label is that with the most neighbors
    [~,bestLabelIndex] = max(counts);
    digitsLabels{i} = labels{bestLabelIndex};

    %% alternative for 1NN: prune using multidimensional extension of Keogh's Lower Bound
%     digitsLabels{i} = dtwClosestLabelUsingLowerBound(coeffs,refSet);
    
    %% plot dtw alignment of mfcc coeffs of current word and its closest
    if exist("shouldPlot","var") && shouldPlot
        bestRefCoeffs = refSet(Idx(1)).coeffs;
        % recalculate with best ref to get alignment indexes
        [~,IdxCurrent,IdxRef] = dtw(coeffs,bestRefCoeffs,5,'squared');
        figure('Name',sprintf("Word %d of %d, recognized as '%s'",i,numWords,digitsLabels{i}));
        mfccSubplotHelper(221,"Current digit's MFCCs",coeffs);
        mfccSubplotHelper(222,"Best reference digit's MFCCs",bestRefCoeffs);
        mfccSubplotHelper(223,"Current digit's MFCCs Aligned",coeffs(:,IdxCurrent));
        mfccSubplotHelper(224,"Best reference digit's MFCCs Aligned",bestRefCoeffs(:,IdxRef));
        pause;
    end
end % end of word loop
end % end of digitsASR

function mfccSubplotHelper(pos,titleText,mat)
    subplot(pos);
    imagesc(mat);
    axis image; % keep aspect ratio
    set(gca,'YDir','normal');
    xlabel("Frames");
    ylabel("MFC Coefficient");
    title(titleText);
    colorbar('Ticks',linspace(-4,4,5));
    caxis([-4 4]);
    colormap(jet);
end

function label = dtwClosestLabelUsingLowerBound(coeffs,refSet)
    bestDist = Inf;
    bestRef = 0;
    prunedCount = 0;
    for r = 1:length(refSet)
        refCoeffs = refSet(r).coeffs;
        c = coeffs';
        q = coeffs';
        u = max(q,[],1);
        l = min(q,[],1);
        lowerBound = sqrt(sum(((c > u).*(c - u) + (c < l).*(l - c)).^2,'all'));
%         trueDist = dtw(coeffs,refCoeffs,'squared');
%         fprintf("LowerBound %f Actual %f\n",lowerBound,trueDist);
%         assert(lowerBound <= trueDist, "lower bound bigger than true distance");
        if lowerBound < bestDist
            trueDist = dtw(coeffs,refCoeffs,'squared');
            if trueDist < bestDist
                bestDist = trueDist;
                bestRef = r;
            end
        else
            prunedCount = prunedCount + 1;
        end
    end
%     fprintf("Pruned %d of %d\n",prunedCount,length(refSet));
    label = refSet(bestRef).label;
end