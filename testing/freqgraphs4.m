% Define parameters
filename = 'Experiment-3-Pump'; % Replace with your CSV file name
start_index = 1; % Starting index for FFT
end_index = 2000;   % Ending index for FFT
fs = .5; % Sampling frequency (Hz) - adjust as necessary

% Read the CSV file
data = readtable(filename);

% Assuming the temperature data is in column 43
temperature = data{:, 43};

% Extract the specified range of data points
section_data = temperature(start_index:end_index);

% Plot the original temperature data for the specified range using a normal plot
figure;
subplot(2, 1, 1);
plot(start_index:end_index, section_data);
title('Temperature Data from 1000 to 1500');
xlabel('Sample Index');
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
non_zero_indices = 1:length(f); % Exclude the first index (0 frequency)
f_non_zero = f(non_zero_indices);
P1_non_zero = P1(non_zero_indices);

% Create subplot for FFT using stem (excluding zero frequency)
subplot(2, 1, 2);
stem(f_non_zero, P1_non_zero, 'filled');
title('FFT of Temperature Data (1000 to 1500, Excluding 0 Hz)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis');
