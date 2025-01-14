% Load CSV file
data = readtable('Experiment-1-Pump.csv');

% Convert the time column (assume it's the first column) to datetime
time_utc = datetime(data{:,2}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');  % Adjust format if needed

% Extract the signal values
signal = data{:,59};  % Assuming the signal is in column 59

% Convert datetime to seconds relative to the first timestamp (for interpolation)
time_seconds = seconds(time_utc - time_utc(1));  % Time in seconds from start

% Interpolate the signal with respect to regular time intervals (based on seconds)
new_time_seconds = min(time_seconds):2:max(time_seconds);  % Regular 2-second intervals
interpolated_signal = interp1(time_seconds, signal, new_time_seconds, 'linear');

% Parameters for sliding window analysis
window_size = 200; % Number of points per segment
overlap = 100; % Overlap between windows
num_segments = floor((length(interpolated_signal) - window_size) / (window_size - overlap)) + 1;

% Thresholds
threshold_improvement = 0.1; % Sensitivity for detecting significant changes
slope_threshold = 0.01;       % Threshold for detecting rapid increases/decreases

% Store transition points, confidence levels, and trend markers
transitions = [];
confidence_data = zeros(num_segments, 3); % [Window Midpoint, Linear R^2, Exponential R^2]
rapid_changes = []; % Array to store midpoints where rapid changes occur

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
    slope = lin_coeffs(1);  % Slope of the linear fit
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

    % Identify rapid changes based on the slope
    if abs(slope) > slope_threshold
        rapid_changes = [rapid_changes; midpoint_x]; % Mark rapid change at midpoint
    end
end

% Plotting the signal and transition points
subplot(2, 1, 1); % First plot for transitions and rapid changes
plot(new_time_seconds, interpolated_signal, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410], 'DisplayName', 'Interpolated Signal');
hold on;
plot(transitions, interpolated_signal(ismember(new_time_seconds, transitions)), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Transition Points');
plot(rapid_changes, interpolated_signal(ismember(new_time_seconds, rapid_changes)), 'p', 'MarkerSize', 10, 'MarkerEdgeColor', [0.4940, 0.1840, 0.5560], 'MarkerFaceColor', [0.4940, 0.1840, 0.5560], 'DisplayName', 'Rapid Changes');
xlabel('Time (seconds)', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('Signal Value', 'FontWeight', 'bold', 'FontSize', 12);
legend('Location', 'best');
title('Transition Points and Rapid Changes Detection', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
hold off;

% Plotting confidence levels at midpoints
subplot(2, 1, 2); % Second plot for confidence levels
plot(confidence_data(:,1), confidence_data(:,2) * 100, 'bx', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Linear Fit Confidence');
hold on;
plot(confidence_data(:,1), confidence_data(:,3) * 100, 'rx', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Exponential Fit Confidence');
xlabel('Time (seconds, Midpoints of Windows)', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('Fit Confidence (%)', 'FontWeight', 'bold', 'FontSize', 12);
title('Fit Confidence Levels Over Time', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;
hold off;