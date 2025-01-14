% Define parameters
filename = 'Experiment-1-Pump'; % Replace with your CSV file name
start_index = 1; % Starting index for FFT
end_index = 5600;   % Ending index for FFT
fs = 1; % Sampling frequency (Hz) - adjust as necessary

% Read the CSV file
data = readtable(filename);

% Assuming the temperature data is in column 43
temperature = data{:, 43};

% Extract the specified range of data points
section_data = temperature(start_index:end_index);

% Plot the original temperature data for the specified range using stem
figure;
subplot(2, 1, 1);
stem(start_index:end_index, section_data, 'filled');
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
f = fs*(0:(L/2))/L; % Frequency axis

% Create subplot for FFT using stem
subplot(2, 1, 2);
stem(f, P1, 'filled');
title('FFT of Temperature Data (1000 to 1500)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis');
