function w = smoothingFilter(x,shouldPlot,Fs)
y = medfilt1(x,5,'omitnan','truncate'); % no delay
y = filter([1/4 1/2 1/4],1,y); % delay of 1 sample
y = y(2:end); % compensate delays
y(end+1) = y(end);

z = x - y;
z = medfilt1(z,5,'omitnan','truncate');
z = filter([1/4 1/2 1/4],1,z);
z = z(2:end); % compensate delays
z(end+1) = z(end);

w = y + z;

%% plots
if exist("shouldPlot","var") && shouldPlot
    figure;
    t = (0:length(x)-1)/Fs;
    subplot(2,1,1);
    hold on;
    stem(t,x);
    stem(t,w);
    xlabel("Time (s)");
    ylabel("Amplitude");
    legend("Original","Smoothed");
    grid on;

    subplot(2,1,2);
    stem(t,x - w);
    xlabel("Time (s)");
    ylabel("Difference");
    grid on;
    pause;
end
