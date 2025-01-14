% Define parameters
filename = 'Experiment-2-Pump'; % Replace with your CSV file name
section_length = 100; % Length of each section (number of data points)
fs = .5; % Sampling frequency (Hz) - adjust as necessary

% Read the CSV file
data = readtable(filename);

% Assuming the temperature data is in the first column
temperature = data{1000:1500, 43};

% Plot the original temperature data
figure;

subplot(num_sections + 1, 1, 1); % +1 for the original data plot
plot(temperature);
title('Original Temperature Data');
xlabel('Time (samples)');
ylabel('Temperature');
grid on;

% Calculate the number of sections
num_sections = floor(length(temperature) / section_length);

for i = 1:num_sections
    % Define the current section of data
    start_index = (i-1) * section_length + 1;
    end_index = start_index + section_length - 1;
    section_data = temperature(start_index:end_index);
    
    % Perform FFT
    L = length(section_data);
    Y = fft(section_data);
    P2 = abs(Y/L); % Two-sided spectrum
    P1 = P2(1:L/2+1); % Single-sided spectrum
    P1(2:end-1) = 2*P1(2:end-1); % Correct amplitude
    f = fs*(0:(L/2))/L; % Frequency axis
    
    % Create subplot for each section
    subplot(num_sections + 1, 1, i + 1);
    plot(f, P1);
    title(['FFT of Section ' num2str(i)]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    grid on;
end

% Adjust the layout
sgtitle('Temperature Data and FFT Analysis');
