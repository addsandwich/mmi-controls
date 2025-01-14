% Define parameters
filename = 'Experiment-3-Pump'; % Replace with your CSV file name% \
fs = 2; % Desired sampling frequency (Hz)
segment_length = 440; % Length of each segment for FFT
new_sample_rate = 2; % New sample interval in seconds

% Define your segments as a matrix where each row is [start_index, end_index]
segments = [1400, 1505; 1506, 1570;1571,1700;1701, 1850; 1851, 2000]; % Example segments

% Read the CSV file
data = readtable(filename);

startidxer = 1400;
endidxer = 2000;

% Assuming the temperature data is in column 43 and timestamps in column 2
temperature = data{startidxer:endidxer, 43};
timestamps_utc = data{startidxer:endidxer, 2}; % Read timestamps

% Create a regular time vector based on the new sample rate
start_time = min(timestamps_utc);
end_time = max(timestamps_utc);
regular_time = start_time:seconds(new_sample_rate):end_time; % Regular time vector

% Interpolate temperature data to match the regular time vector
interpolated_temp = interp1(timestamps_utc, temperature, regular_time, 'linear');

% Create figure for both temperature and frequency plots
figure;

colors = lines(floor(length(interpolated_temp) / segment_length)); % Generate distinct colors

% Subplot for interpolated temperature data
subplot(2, 1, 1);
hold on; % Hold on to overlay multiple plots

for segment = 1:floor(length(interpolated_temp) / segment_length)
    start_index = (segment - 1) * segment_length + 1;
    end_index = min(segment * segment_length, length(interpolated_temp)); % Ensure we don't exceed array bounds
    section_time = regular_time(start_index:end_index); % Extract time for the segment
    section_data = interpolated_temp(start_index:end_index); % Extract segment data
    
    % Plot the segment of temperature data with specified color
    plot(section_time, section_data, 'Color', colors(segment, :), 'LineWidth', 1.5); 



    %plot(regular_time, interpolated_temp);
    title('Interpolated Temperature Data');
    xlabel('Time (UTC)');
    ylabel('Temperature');
    ylim([22 35]); % Set static y-axis limits for temperature
    grid on;
end

% Prepare for FFT plots
subplot(2, 1, 2);
hold on; % Hold on to overlay multiple plots

% Create a cell array for legend entries
legend_entries = {};

% Loop over segments of the interpolated temperature data
for start_index = 1:segment_length:(length(interpolated_temp) - segment_length + 1)
    end_index = start_index + segment_length - 1; % Calculate the end index for the segment
    section_data = interpolated_temp(start_index:end_index); % Extract segment data
    seg = floor(end_index/segment_length);
    
    % Perform FFT
    L = length(section_data);
    Y = fft(section_data);
    P2 = abs(Y/L); % Two-sided spectrum
    P1 = P2(1:L/2+1); % Single-sided spectrum
    P1(2:end-1) = 2*P1(2:end-1); % Correct amplitude
    
    % Exclude zero frequency
    f = fs*(0:(L/2))/L; % Frequency axis
    non_zero_indices = 7:length(f); % Exclude the first index (0 frequency)
    f_non_zero = f(non_zero_indices);
    P1_non_zero = P1(non_zero_indices);
    
    % Create a stem plot for each segment
    stem(f_non_zero, P1_non_zero, "filled", 'Color', colors(seg, :)); % Use stem for overlay
    
    % Add an entry to the legend for this segment
    legend_entries{end+1} = string(datetime(regular_time(start_index)));
end

% Finalize the FFT plot
title('Overlayed FFT of Interpolated Temperature Data Segments');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
ylim([0 .1]); % Set static y-axis limits for frequency magnitude
xlim([.05 .5]); % Set static y-axis limits for frequency magnitude
grid on;

% Add the legend
legend(legend_entries, 'Location', 'northeastoutside');
hold off; % Release the hold

% Adjust layout
sgtitle('Temperature Data and Overlayed FFT Analysis');
