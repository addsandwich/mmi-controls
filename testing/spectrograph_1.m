% Load CSV file
data = readtable('Experiment-1-Pump.csv');

% Convert the time column (assume it's the first column) to datetime
time_utc = datetime(data{:,2}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');  % Adjust format if needed

% Convert datetime to seconds relative to the first timestamp
signal = data{:,43};  % Extract the signal values (second column)


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

% Plot the spectrogram with UTC time on the x-axis
figure;
surf(t_utc, f, 10*log10(abs(p)), 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (UTC)');
ylabel('Frequency (Hz)');
title('Spectrogram - Frequency change over time');
colorbar;

