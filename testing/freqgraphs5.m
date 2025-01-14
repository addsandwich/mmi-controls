% Define parameters
filename = 'Experiment-1-Pump'; % Replace with your CSV file name
start_index = 1; % Starting index for FFT
end_index = 5600;   % Ending index for FFT
fs = 1; % Sampling frequency (Hz) - adjust as necessary

% Read the CSV file
data = readtable(filename);

% Assuming the temperature data is in column 43 and timestamps in column 2
temperature = data{:, 43};
timestamps_utc = data{:, 2}; % Read timestamps

% Convert UTC timestamps to datetime
%timestamps_utc = datetime(timestamps_utc, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
%timestamps_edt = timestamps_utc; % Create a new variable for EDT
%timestamps_edt.TimeZone = 'America/New_York'; % Convert to EDT

% Extract the specified range of data points
section_data = temperature(start_index:end_index);
time_range = timestamps_utc(start_index:end_index); % Corresponding timestamps

% Plot the original temperature data for the specified range using a normal plot
figure;
subplot(2, 1, 1);
plot(time_range, section_data);
title('Temperature Data');
xlabel('Time (UTC)');
ylabel('Temperature');
grid on;

% Perform FFT
L = length(section_data);
Y = fft(section_data);
P2 = abs(Y/L); % Two-sided spectrum
P1 = P2(1:L/2+1); % Single-sided spectrum
P1(2:end-1) = 2*P1(2:end-1); % Correct amplitude

% Exclude zero frequency
f = fs*(0:(L/2))/L; % Frequency axis
non_zero_indices = 2:length(f); % Exclude the first index (0 frequency)
f_non_zero = f(non_zero_indices);
P1_non_zero = P1(non_zero_indices);

% Create subplot for FFT using stem (excluding zero frequency)
subplot(2, 1, 2);
stem(f_non_zero, P1_non_zero, 'filled');
title('FFT of Temperature Data (Excluding 0 Hz)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis');
