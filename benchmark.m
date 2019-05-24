load('refSet.mat');

rng(0); %set seed for reproducibility of randsample()
files = dir("isolated_digits_ti_test/**/*.wav");
numTestFiles = length(files);
testFiles = randsample(files,numTestFiles);

labels = {'O','Z','1','2','3','4','5','6','7','8','9'};
confMat = zeros(length(labels));
% recognize numTestFiles digits and calculate confusion matrix
tic;
for i = 1:numTestFiles
    filePath = fullfile(testFiles(i).folder, testFiles(i).name);
    trueLabel = testFiles(i).name(1); % first char is the class label
    fprintf("%.2f%% Processing %s...\n",100*i/numTestFiles,filePath);
    digitLabel = digitsASR(filePath,refSet,false);
    assert(length(digitLabel)==1,"Detected %d words in a single-word test audio signal.",length(digitLabel));
    trueLabelIdx = find(strcmp(labels,trueLabel));
    detectedLabelIdx = find(strcmp(labels,digitLabel));
    confMat(detectedLabelIdx,trueLabelIdx) = confMat(detectedLabelIdx,trueLabelIdx) + 1;
end
elapsedTime = toc;
fprintf("Benchmark time: %f seconds\n",elapsedTime);
fprintf("Avg digit recognition time: %f seconds\n",elapsedTime/numTestFiles);
plotConfMat(confMat,labels);
