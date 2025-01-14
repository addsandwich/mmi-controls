% Define parameters
filename = ['Experiment-3-Pump']; % Replace with your CSV file name
fs = .5; % Sampling frequency (Hz) - adjust as necessary

% Read the CSV file
data = readtable(filename);

% Assuming the temperature data is in column 43 and timestamps in column 2
temperature = data{:, 43};
timestamps_utc = data{:, 2}; % Read timestamps

% Convert timestamps to datetime format (keeping UTC)
%timestamps_utc = datetime(timestamps_utc, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');

% Define the first range
start_index_1 = 400; % Starting index for the first range
end_index_1 = 700;   % Ending index for the first range

% Now handle the second range
start_index_2 = 1400;
end_index_2 = 1500;

% Extract the first range of data points
section_data_1 = temperature(start_index_1:end_index_1);
time_range_1 = timestamps_utc(start_index_1:end_index_1); % Corresponding timestamps

% Plot the original temperature data for the first range using a normal plot
figure;

% Subplot for the first range
subplot(2, 1, 1);
plot(time_range_1, section_data_1);
title('Temperature Data (Normal)');
xlabel('Time (UTC)');
ylabel('Temperature');
ylim([0 40]); % Set static y-axis limits for temperature
grid on;

% Perform FFT for the first range
L1 = length(section_data_1);
Y1 = fft(section_data_1);
P2_1 = abs(Y1/L1); % Two-sided spectrum
P1_1 = P2_1(1:L1/2+1); % Single-sided spectrum
P1_1(2:end-1) = 2*P1_1(2:end-1); % Correct amplitude

% Exclude zero frequency
f1 = fs*(0:(L1/2))/L1; % Frequency axis
non_zero_indices_1 = 2:length(f1); % Exclude the first index (0 frequency)
f_non_zero_1 = f1(non_zero_indices_1);
P1_non_zero_1 = P1_1(non_zero_indices_1);

% Create subplot for FFT using stem (excluding zero frequency)
subplot(2, 1, 2);
stem(f_non_zero_1, P1_non_zero_1, 'filled');
title('FFT of Temperature Data (Normal, Excluding 0 Hz)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
ylim([0 5]); % Set static y-axis limits for frequency magnitude
grid on;

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis (Normal)');

% Extract the second range of data points
section_data_2 = temperature(start_index_2:end_index_2);
time_range_2 = timestamps_utc(start_index_2:end_index_2); % Corresponding timestamps

% Plot the original temperature data for the second range using a normal plot
figure;

% Subplot for the second range
subplot(2, 1, 1);
plot(time_range_2, section_data_2);
title(['Temperature Data (Ramp Up)']);
xlabel('Time (UTC)');
ylabel('Temperature');
ylim([0 40]); % Set static y-axis limits for temperature
grid on;

% Perform FFT for the second range
L2 = length(section_data_2);
Y2 = fft(section_data_2);
P2_2 = abs(Y2/L2); % Two-sided spectrum
P1_2 = P2_2(1:L2/2+1); % Single-sided spectrum
P1_2(2:end-1) = 2*P1_2(2:end-1); % Correct amplitude

% Exclude zero frequency
f2 = fs*(0:(L2/2))/L2; % Frequency axis
non_zero_indices_2 = 2:length(f2); % Exclude the first index (0 frequency)
f_non_zero_2 = f2(non_zero_indices_2);
P1_non_zero_2 = P1_2(non_zero_indices_2);

% Create subplot for FFT using stem (excluding zero frequency)
subplot(2, 1, 2);
stem(f_non_zero_2, P1_non_zero_2, 'filled');
title('FFT of Temperature Data (Ramp Up)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
ylim([0 5]); % Set static y-axis limits for frequency magnitude
grid on;

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis (Ramp Up)');
