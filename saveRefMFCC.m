tic;
files = dir("isolated_digits_ti_train/**/*.wav");
for i = length(files):-1:1
    filePath = fullfile(files(i).folder, files(i).name);
    label = files(i).name(1); % first char is the class label
    refSet(i) = processFile(filePath,label);
end
save("refSet.mat","refSet");
toc;

% calculates MFCCs and returns a struct with fields: label, coeffs, delta, deltaDelta
function outputStruct = processFile(filename,label)
    fprintf("Processing %s...\n",filename);
    [x, FsOrig] = audioread(filename);
    x = x/max(max(x),-min(x));

    Fs = 8000;
    x = resample(x, Fs, FsOrig);

    hpforder = 30;              %% order of highpass filter  
    lowcut = 100;               %% low band reject frequency   (Hz)
    highcut = 200;              %% high band cut-off frequency (Hz)
    hpfilter = firpm(hpforder,[0 lowcut highcut Fs/2]/(Fs/2),[0 0 1 1]);
    x = filter(hpfilter,1,x);

    frameDuration = 30;         %% Frame Duration in ms
    L = frameDuration*Fs/1000;  %% Frame Duration in samples
    frameShift = 10;            %% Frame Shift in ms
    R = frameShift*Fs/1000;     %% Frame Shift in samples

    [firstSample,lastSample] = detectWordsEndpoints(x,Fs,L,R,false);
    assert(length(firstSample)==1,"Detected %d words in a single-word reference audio signal.",length(firstSample));
    x = x(firstSample:lastSample); % extracted word
    [coeffs,delta,deltaDelta] = normalizedMFCC(x,Fs,L,R);
    outputStruct = struct("label",label,"coeffs",coeffs,"delta",delta,"deltaDelta",deltaDelta);
end
