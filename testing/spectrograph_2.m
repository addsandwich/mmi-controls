% Load CSV file
data = readtable('Experiment-1-Pump.csv');

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

% Apply STFT to the interpolated signal
[s, f, t, p] = spectrogram(filtered_signal, hamming(128), 120, 128, 1/2); 

% Adjust t to match the new UTC times (convert from seconds back to datetime)
t_utc = new_time_utc(round(t * 1/2) + 1);  % Adjust t based on sampling rate (1/2 Hz in this example)

% Create a figure with two subplots: one for the interpolated data and one for the spectrogram
figure;

% 1st subplot: Plot the interpolated signal
subplot(2,1,1);  % Two rows, one column, first plot
plot(new_time_utc, interpolated_signal, 'b');  % Plot the interpolated signal
xlabel('Time (UTC)');
ylabel('Signal');
title('Interpolated Signal Over Time');
grid on;

% 2nd subplot: Plot the spectrogram
subplot(2,1,2);  % Two rows, one column, second plot
surf(t_utc, f, 10*log10(abs(p)), 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (UTC)');
ylabel('Frequency (Hz)');
title('Spectrogram - Frequency change over time');
colorbar;


% Convert power to dB
p_db = 10*log10(abs(p));

% Define frequency range of interest
freq_range = (f >= 0.05 & f <= 0.25);  % Indices for frequencies between 0.05 Hz and 0.25 Hz

% Calculate average power in the defined frequency range
avg_power = mean(p_db(freq_range, :), 1);  % Average power across the specified frequency range for each time bin

% Detect significant shifts in average power
threshold = -30;  % Set a threshold for identifying significant shifts
failure_times = t_utc(avg_power > threshold);  % Times where the average power exceeds the threshold

% Create a figure with two subplots: one for the interpolated data and one for the average power
figure;

% 1st subplot: Plot the interpolated signal
subplot(3,1,1);  % Three rows, one column, first plot
plot(new_time_utc, interpolated_signal, 'b');  % Plot the interpolated signal
xlabel('Time (UTC)');
ylabel('Signal');
title('Interpolated Signal Over Time');
grid on;

% 2nd subplot: Plot average power in the frequency range
subplot(3,1,2);  % Three rows, one column, second plot
plot(new_time_utc, avg_power, 'r');  % Plot the average power in the frequency range
xlabel('Time (UTC)');
ylabel('Average Power (dB)');
title('Average Power in Frequency Range (0.05 - 0.25 Hz)');
grid on;

% 3rd subplot: Plot the spectrogram
subplot(3,1,3);  % Three rows, one column, third plot
surf(t_utc, f, p_db, 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (UTC)');
ylabel('Frequency (Hz)');
title('Spectrogram - Frequency Change Over Time');
colorbar;

% Mark detected failure times on the average power plot
hold on;
for i = 1:length(failure_times)
    xline(failure_times(i), 'k--', 'LineWidth', 2);  % Black dashed line for each detected failure
end