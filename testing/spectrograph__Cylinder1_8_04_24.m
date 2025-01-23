clear;
% Load CSV file
data = readtable('Experiment-1-Pump.csv');
threshold = -20;

% Convert the time column (assume it's the first column) to datetime
time_utc = datetime(data{:,2}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');  % Adjust format if needed

% Extract the signal values
signal = data{:,43};  % Assuming the signal is in column 43

% Convert datetime to seconds relative to the first timestamp (for interpolation)
time_seconds = seconds(time_utc - time_utc(1));  % Time in seconds from start

% Interpolate the signal with respect to regular time intervals (based on seconds)
new_time_seconds = min(time_seconds):2:max(time_seconds);  % Regular 2-second intervals
interpolated_signal = interp1(time_seconds, signal, new_time_seconds, 'linear');

% Design a high-pass filter with a cutoff frequency of 0.01 Hz
cutoff_frequency = 0.002;  % Adjust as needed
Fs = 1 / 2;  % Sampling frequency (1 sample every 2 seconds)
[b, a] = butter(4, cutoff_frequency / (Fs/2), 'high');

% Apply the filter to the signal
filtered_signal = filtfilt(b, a, interpolated_signal);

% Convert back to UTC time for plotting
new_time_utc = time_utc(1) + seconds(new_time_seconds);  % Convert back to UTC for the new interpolated time

% Apply STFT to the filtered signal
[s, f, t, p] = spectrogram(filtered_signal, hamming(128), 120, 128, Fs); 

% Adjust t to match the new UTC times (convert from seconds back to datetime)
t_utc = new_time_utc(round(t * 1/2) + 1);  % Adjust t based on sampling rate (1/2 Hz in this example)

% Convert power to dB
p_db = 10*log10(abs(p));

% Define frequency range of interest
freq_range = (f >= 0.05 & f <= 0.25);  % Indices for frequencies between 0.05 Hz and 0.25 Hz

% Calculate average power in the defined frequency range
avg_power = mean(p_db(freq_range, :), 1);  % Average power across the specified frequency range for each time bin

% Create UTC time vector for the average power
avg_power_time = new_time_utc(1) + seconds(t);  % Match the average power time to the time bins

% Define the time range you want to display
start_time = new_time_utc(2000);  % Start time (first timestamp in the interpolated signal)
end_time = new_time_utc(3000);  % End time (last timestamp in the interpolated signal)

% Create a figure with two subplots: one for the interpolated data and one for the average power
figure;
%colormap(jet); % You can replace 'jet' with other colormaps like 'hot', 'parula', or 'turbo'
t = tiledlayout(4,1, 'TileSpacing','none','Padding','none');

title_size = 16;
font_size = 14;

% 1st subplot: Plot the interpolated signal
%ax1 = subplot(4,1,1);  % Three rows, one column, first plot
ax1 = nexttile;
plot(new_time_utc, interpolated_signal, 'b');  % Plot the interpolated signal
xlabel('Time (UTC)', 'FontSize', font_size);
ylabel('Tempurature (C)', 'FontSize', font_size);
title('Interpolated Signal Over Time', 'FontSize', title_size);
grid on;
xlim([start_time, end_time]);  % Set xlim for this subplot

% 2nd subplot: Plot average power in the frequency range
%ax2 = subplot(4,1,2);  % Three rows, one column, second plot
ax2 = nexttile;
plot(avg_power_time, avg_power, 'r');  % Plot the average power in the frequency range
xlabel('Time (UTC)', 'FontSize', font_size);
ylabel('Average Power (dB)', 'FontSize', font_size);
title('Average Power in Frequency Range (0.05 - 0.25 Hz)', 'FontSize', title_size);
grid on;
xlim([start_time, end_time]);  % Set xlim for this subplot

% 3rd subplot: Plot the spectrogram
%ax3 = subplot(4,1,3);  % Three rows, one column, third plot
ax3 = nexttile;
surf(t_utc, f, p_db, 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (UTC)', 'FontSize', font_size);
ylabel('Frequency (Hz)', 'FontSize', font_size);
title('Spectrogram - Frequency Change Over Time', 'FontSize', title_size);
colorbar;
xlim([start_time, end_time]);  % Set xlim for this subplot

% 4th subplot: Plot the spectrogram
%ax4 = subplot(4,1,4);  % Three rows, one column, third plot
ax4 = nexttile;
surf(t_utc, f, p_db, 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (UTC)', 'FontSize', font_size);
ylabel('Frequency (Hz)', 'FontSize', font_size);
title('Spectrogram - Anomalous Areas', 'FontSize', title_size);
colorbar;
xlim([start_time, end_time]);  % Set xlim for this subplot

%linkaxes([ax1, ax2, ax3, ax4], 'x')

yticks = ax1.YTick;
ax1.YTick = yticks(1:end-1);
yticks = ax2.YTick;
ax2.YTick = yticks(1:end-1);
yticks = ax3.YTick;
ax3.YTick = yticks(1:end-1);
yticks = ax4.YTick;
ax4.YTick = yticks(1:end-1);


% Mark detected failure times on the average power plot
hold on;
failure_indices = find(avg_power > threshold);
for i = 1:length(failure_indices)
    xline(avg_power_time(failure_indices(i)), 'k--', 'LineWidth', 2);  % Black dashed line for each detected failure
end
