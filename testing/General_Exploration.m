% Define parameters
filename = ['Experiment-1-Pump']; % Replace with your CSV file name% \
fs = .5; % Sampling frequency (Hz) - adjust as necessary
segment_length = 600; % Length of each segment for FFT

% Read the CSV file
data = readtable(filename);

startidxer = 1;
endidxer = 3000;

% Assuming the temperature data is in column 43 and timestamps in column 2
%temperature = data{startidxer:endidxer, 43};
%timestamps_utc = data{startidxer:endidxer, 2}; % Read timestamps
% Assuming the temperature data is in column 43 and timestamps in column 2
temperature = data{:, 43};
timestamps_utc = data{:, 2}; % Read timestamps


% Create figure for both temperature and frequency plots
figure;


%indexsection = start_index:fs:end_index

% Subplot for temperature data
subplot(2, 1, 1);
plot(timestamps_utc, temperature);
title('Temperature Data');
xlabel('Time (UTC)');
ylabel('Temperature');
ylim([18 40]); % Set static y-axis limits for temperature
grid on;

% Prepare for FFT plots
subplot(2, 1, 2);
hold on; % Hold on to overlay multiple plots

% Create a cell array for legend entries
legend_entries = {};

% Loop over segments of the temperature data
for start_index = 1:segment_length:(length(temperature) - segment_length + 1)
    end_index = start_index + segment_length - 1; % Calculate the end index for the segment
    section_data = temperature(start_index:end_index); % Extract segment data
    
    % Perform FFT
    L = length(section_data);
    Y = fft(section_data);
    P2 = abs(Y/L); % Two-sided spectrum
    P1 = P2(1:L/2+1); % Single-sided spectrum
    P1(2:end-1) = 2*P1(2:end-1); % Correct amplitude
    
    % Exclude zero frequency
    f = fs*(0:(L/2))/L; % Frequency axis
    non_zero_indices = 6:length(f); % Exclude the first index (0 frequency)
    f_non_zero = f(non_zero_indices);
    P1_non_zero = P1(non_zero_indices);
    
    % Create a stem plot for each segment
    stem(f_non_zero, P1_non_zero, 'filled'); % Use stem for overlay
    
    % Add an entry to the legend for this segment
    %legend_entries{end+1} = string(datetime(timestamps_utc(start_index)));
    legend_entries{end+1} = string(datetime(timestamps_utc(start_index)));
end

% Finalize the FFT plot
title('Overlayed FFT of Temperature Data Segments');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
ylim([0 0.15]); % Set static y-axis limits for frequency magnitude
xlim([0 0.15]); % Set static y-axis limits for frequency magnitude
grid on;

% Add the legend
legend(legend_entries, 'Location', 'northeastoutside');

hold off; % Release the hold

% Adjust layout
sgtitle('Temperature Data and Overlayed FFT Analysis');
