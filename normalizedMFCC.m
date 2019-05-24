function [coeffs,delta,deltaDelta] = normalizedMFCC(signal,Fs,L,R,shouldPlot)
[coeffs,delta,deltaDelta] = mfcc(signal,Fs,'NumCoeffs',13,...
    'WindowLength',L,'OverlapLength',L-R,...
    'DeltaWindowLength',5,'LogEnergy','Ignore');
coeffs = coeffs'; delta = delta'; deltaDelta = deltaDelta';
% matrixes of size NumCoeffs-by-NumFrames
% normalize by substracting (dividing) by mean (std) of each Coeff (each row)
coeffs = (coeffs - mean(coeffs,2))./std(coeffs,[],2);
delta = (delta - mean(delta,2))./std(delta,[],2);
deltaDelta = (deltaDelta - mean(deltaDelta,2))./std(deltaDelta,[],2);

if exist("shouldPlot","var") && shouldPlot
    figure;
    imagesc(coeffs);
    axis image; % keep aspect ratio
    set(gca,'YDir','normal');
    xlabel("Frames");
    ylabel("MFC Coefficient");
    title("Normalized MFC Coefficients, (coeff - \mu)/\sigma");
    colorbar('Ticks',linspace(-4,4,5));
    caxis([-4 4]);
    colormap(jet);
end

