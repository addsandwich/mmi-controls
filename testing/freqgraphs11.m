% Define parameters
filename = 'Experiment-3-Pump'; % Replace with your CSV file name% \
fs = 1; % Desired sampling frequency (Hz)
segment_length = 440; % Length of each segment for FFT
new_sample_rate = 1; % New sample interval in seconds

% Define your segments as a matrix where each row is [start_index, end_index]
segments = [1, 1180; 1181, 1620;1621,1920;1921,2150;2151,2380;2381, 2650; 2651, 4554]; % Example segments
%segments = [1, 1180; 1181, 1585;1586,1895;1896,2130;2131,2500; 2501, 4554]; % Example segments


% Read the CSV file
data = readtable(filename);

startidxer = 1400;
endidxer = 2000;

% Assuming the temperature data is in column 43 and timestamps in column 2
temperature = data{startidxer:endidxer, 43};
timestamps_utc = data{startidxer:endidxer, 2}; % Read timestamps
pressure = data{startidxer:endidxer, 59};

% Create a regular time vector based on the new sample rate
start_time = min(timestamps_utc);
end_time = max(timestamps_utc);
regular_time = start_time:seconds(new_sample_rate):end_time; % Regular time vector

% Interpolate temperature data to match the regular time vector
interpolated_temp = interp1(timestamps_utc, temperature, regular_time, 'linear');
interpolated_pressure = interp1(timestamps_utc, pressure, regular_time, 'linear');

% Create figure for both temperature and frequency plots
figure;

colors = lines(floor(length(interpolated_temp) / segment_length)); % Generate distinct colors

% Subplot for interpolated temperature data
subplot(3, 1, 1);
hold on; % Hold on to overlay multiple plots

for i = 1:size(segments, 1)
    start_index = segments(i, 1);
    end_index = segments(i, 2);
    section_time = regular_time(start_index:end_index); % Extract time for the segment
    section_data = interpolated_pressure(start_index:end_index); % Extract segment data
    
    % Plot the segment of temperature data with specified color
    plot(section_time, section_data, 'Color', colors(i, :), 'LineWidth', 1.5); 

    %plot(regular_time, interpolated_temp);
    title('Pressure Data');
    xlabel('Time (UTC)');
    ylabel('Pressure BAR');
    ylim([0 30]); % Set static y-axis limits for temperature
    grid on;
end


% Subplot for interpolated temperature data
subplot(3, 1, 2);
hold on; % Hold on to overlay multiple plots

for i = 1:size(segments, 1)
    start_index = segments(i, 1);
    end_index = segments(i, 2);
    section_time = regular_time(start_index:end_index); % Extract time for the segment
    section_data = interpolated_temp(start_index:end_index); % Extract segment data
    
    % Plot the segment of temperature data with specified color
    plot(section_time, section_data, 'Color', colors(i, :), 'LineWidth', 1.5); 



    %plot(regular_time, interpolated_temp);
    title('Interpolated Temperature Data');
    xlabel('Time (UTC)');
    ylabel('Temperature(C)');
    ylim([22 35]); % Set static y-axis limits for temperature
    grid on;
end


% Design a high-pass filter
cutoff_freq = .1; % Cutoff frequency (Hz)
order = 4; % Order of the filter
hp_filter =designfilt('highpassiir','StopbandFrequency',0.045, ...
    'PassbandFrequency',0.05,'SampleRate',1);

%hp_filter =designfilt('highpassfir','FilterOrder',20,'CutoffFrequency',0.02);

% Apply the filter
%filtered_data = filter(hp_filter, interpolated_temp);

% Prepare for FFT plots
subplot(3, 1, 3);
hold on; % Hold on to overlay multiple plots

% Create a cell array for legend entries
legend_entries = {};
tograph = [1,2,4,5];
% Loop over segments of the interpolated temperature data
for ix = 1:length(tograph)
    i = tograph(ix);
    start_index = segments(i, 1);
    end_index = segments(i, 2);
    section_data = interpolated_temp(start_index:end_index); % Extract segment data
    
    % Perform FFT
    L = length(section_data);
    Y = fft(section_data);
    P2 = abs(Y/L); % Two-sided spectrum
    P1 = P2(1:L/2+1); % Single-sided spectrum
    P1(2:end-1) = 2*P1(2:end-1); % Correct amplitude
    
    % Exclude zero frequency
    f = fs*(0:(L/2))/L; % Frequency axis
    non_zero_indices = 4:length(f); % Exclude the first index (0 frequency)
    f_non_zero = f(non_zero_indices);
    P1_non_zero = P1(non_zero_indices);
    
    % Create a stem plot for each segment
    stem(f_non_zero, P1_non_zero, "filled", 'Color', colors(i, :)); % Use stem for overlay
    %plot(f_non_zero, P1_non_zero, 'Color', colors(i, :)); % Use stem for overlay

    % Add an entry to the legend for this segment
    legend_entries{end+1} = string(datetime(regular_time(start_index)));
end

% Finalize the FFT plot
title('Overlayed FFT of Interpolated Temperature Data Segments');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
ylim([0 .05]); % Set static y-axis limits for frequency magnitude
xlim([.06 .25]); % Set static y-axis limits for frequency magnitude
grid on;

% Add the legend
legend(legend_entries, 'Location', 'northeastoutside');
hold off; % Release the hold

% Adjust layout
sgtitle('Temperature Data and Overlayed FFT Analysis');
