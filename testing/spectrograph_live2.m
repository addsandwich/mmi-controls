clear;
% Load CSV file
data = readtable('Experiment-5-Pump.csv');
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

% Maximum number of points to display
max_points = 50;

% Create a figure with two subplots: one for the interpolated data and one for the average power
figure;

% Pre-allocate subplots
subplot(4,1,1);  
h1 = plot(NaT, NaN, 'b');  % Initialize with empty data
xlabel('Time (UTC)');
ylabel('Signal');
title('Interpolated Signal Over Time');
grid on;
hold on;

subplot(4,1,2);  
h2 = plot(NaT, NaN, 'r');  % Initialize with empty data
xlabel('Time (UTC)');
ylabel('Average Power (dB)');
title('Average Power in Frequency Range (0.05 - 0.25 Hz)');
grid on;
hold on;

% % Initialize the spectrogram plot with valid data
% subplot(4,1,3);
% h3 = imagesc(t_utc, f, zeros(size(p_db)));  % Initialize with zeros instead of NaN
% set(gca, 'YDir', 'normal');  % Ensure y-axis is in normal direction
% xlabel('Time (UTC)');
% ylabel('Frequency (Hz)');
% title('Spectrogram - Frequency Change Over Time');
% colorbar;

% Real-time plotting loop
for i = 1:length(new_time_utc)
    % Determine the indices to display (latest `max_points` points)
    start_idx = max(1, i - max_points + 1);
    idx_range = start_idx:i;
    
    % Update the interpolated signal plot with the latest points
    set(h1, 'XData', new_time_utc(idx_range), 'YData', interpolated_signal(idx_range));
    
    % Update the average power plot with the latest points
    if i <= length(avg_power)
        set(h2, 'XData', avg_power_time(idx_range), 'YData', avg_power(idx_range));
    end
    
    % % Update the spectrogram plot with the latest points
    % if i <= length(t)
    %     set(h3, 'XData', t_utc(idx_range), 'CData', p_db(:, idx_range));
    % end
    
    % % Mark detected failure times on the average power plot
    % failure_indices = find(avg_power(1:i) > threshold);
    % for j = 1:length(failure_indices)
    %     if failure_indices(j) >= start_idx  % Only plot if within the visible range
    %         xline(avg_power_time(failure_indices(j)), 'k--', 'LineWidth', 2);  % Black dashed line for each detected failure
    %     end
    % end
    
    % Pause for a real-time effect
    pause(0.1);  % Adjust the pause time as needed
end