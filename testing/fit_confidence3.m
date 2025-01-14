% Load CSV file
data = readtable('Experiment-3-Pump.csv');

% Convert the time column (assume it's the first column) to datetime
time_utc = datetime(data{:,2}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');  % Adjust format if needed

% Extract the signal values
signal = data{:,59};  % Assuming the signal is in column 43

% Convert datetime to seconds relative to the first timestamp (for interpolation)
time_seconds = seconds(time_utc - time_utc(1));  % Time in seconds from start

% Interpolate the signal with respect to regular time intervals (based on seconds)
new_time_seconds = min(time_seconds):2:max(time_seconds);  % Regular 2-second intervals
interpolated_signal = interp1(time_seconds, signal, new_time_seconds, 'linear');

% Parameters for sliding window analysis
window_size = 100; % Number of points per segment
overlap = 50; % Overlap between windows
num_segments = floor((length(interpolated_signal) - window_size) / (window_size - overlap)) + 1;

% Threshold for detecting change
threshold_improvement = 0.1; % Adjust this value for sensitivity

% Store transition points and confidence levels at midpoints
transitions = [];
confidence_data = zeros(num_segments, 3); % [Window Midpoint, Linear R^2, Exponential R^2]

% Perform sliding window analysis
for i = 1:num_segments
    % Define window indices
    start_idx = (i - 1) * (window_size - overlap) + 1;
    end_idx = start_idx + window_size - 1;
    x_seg = new_time_seconds(start_idx:end_idx);
    y_seg = interpolated_signal(start_idx:end_idx);

    % Calculate midpoint of the window
    midpoint_idx = start_idx + floor(window_size / 2);
    midpoint_x = new_time_seconds(midpoint_idx); % Store time in seconds at midpoint

    % Linear fit
    lin_coeffs = polyfit(x_seg, y_seg, 1);
    y_lin_fit = polyval(lin_coeffs, x_seg);
    lin_rmse = sqrt(mean((y_seg - y_lin_fit).^2));
    lin_r2 = 1 - sum((y_seg - y_lin_fit).^2) / sum((y_seg - mean(y_seg)).^2);

    % Exponential fit
    exp_model = fit(x_seg', y_seg', 'exp1');
    y_exp_fit = feval(exp_model, x_seg); % Evaluate the fit model to get predictions over x_seg
    y_exp_fit = y_exp_fit';
    exp_rmse = sqrt(mean((y_seg - y_exp_fit).^2));
    exp_r2 = 1 - sum((y_seg - y_exp_fit).^2) / sum((y_seg - mean(y_seg)).^2);

    % Store confidence values at midpoint
    confidence_data(i, :) = [midpoint_x, lin_r2, exp_r2];

    % Check if exponential fit is significantly better than linear fit
    if (lin_rmse - exp_rmse > threshold_improvement)
        transitions = [transitions; midpoint_x]; % Record transition at midpoint
    end
end

% Plotting the signal and transition points
subplot(2, 1, 1); % First plot for transitions
plot(new_time_seconds, interpolated_signal, 'b', 'DisplayName', 'Interpolated Signal');
hold on;
plot(transitions, interpolated_signal(ismember(new_time_seconds, transitions)), 'ro', 'DisplayName', 'Transition Points');
xlabel('Time (seconds)');
ylabel('Signal Value');
legend;
title('Transition Points Detection');
grid on;
hold off;

% Plotting confidence levels at midpoints
subplot(2, 1, 2); % Second plot for confidence levels
plot(confidence_data(:,1), confidence_data(:,2) * 100, 'bx', 'DisplayName', 'Linear Fit Confidence');
hold on;
plot(confidence_data(:,1), confidence_data(:,3) * 100, 'rx', 'DisplayName', 'Exponential Fit Confidence');
xlabel('Time (seconds, Midpoints of Windows)');
ylabel('Fit Confidence (%)');
title('Fit Confidence Levels Over Time');
legend;
grid on;
hold off;
