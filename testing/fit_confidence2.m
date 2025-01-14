% Sample data (replace with actual data)
x = linspace(0, 10, 100); 
y = x + 0.5 * x.^2 + 2 * exp(0.1 * x); % Sample with linear, quadratic, and exponential behavior

% Parameters for sliding window analysis
window_size = 20; % Number of points per segment
overlap = 10; % Overlap between windows
num_segments = floor((length(y) - window_size) / (window_size - overlap)) + 1;

% Threshold for detecting change
threshold_improvement = 0.1; % Adjust this value for sensitivity

% Store transition points and confidence levels at midpoints
transitions = [];
confidence_data = zeros(num_segments, 4); % [Window Midpoint, Linear R^2, Polynomial R^2, Exponential R^2]

for i = 1:num_segments
    % Define window indices
    start_idx = (i - 1) * (window_size - overlap) + 1;
    end_idx = start_idx + window_size - 1;
    x_seg = x(start_idx:end_idx);
    y_seg = y(start_idx:end_idx);

    % Calculate midpoint of the window
    midpoint_idx = start_idx + floor(window_size / 2);
    midpoint_x = x(midpoint_idx); % Store x value at midpoint

    % Linear fit
    lin_coeffs = polyfit(x_seg, y_seg, 1);
    y_lin_fit = polyval(lin_coeffs, x_seg);
    lin_rmse = sqrt(mean((y_seg - y_lin_fit).^2));
    lin_r2 = 1 - sum((y_seg - y_lin_fit).^2) / sum((y_seg - mean(y_seg)).^2);

    % Polynomial fit (order 2)
    poly_coeffs = polyfit(x_seg, y_seg, 2);
    y_poly_fit = polyval(poly_coeffs, x_seg);
    poly_rmse = sqrt(mean((y_seg - y_poly_fit).^2));
    poly_r2 = 1 - sum((y_seg - y_poly_fit).^2) / sum((y_seg - mean(y_seg)).^2);

    % Exponential fit
    exp_model = fit(x_seg', y_seg', 'exp1');
    y_exp_fit = exp_model(x_seg);
    y_exp_fit = y_exp_fit';
    exp_rmse = sqrt(mean((y_seg - y_exp_fit).^2));
    exp_r2 = 1 - sum((y_seg - y_exp_fit).^2) / sum((y_seg - mean(y_seg)).^2);

    % Store confidence values at midpoint
    confidence_data(i, :) = [midpoint_x, lin_r2, poly_r2, exp_r2];

    % Check if polynomial or exponential fit is significantly better
    if (lin_rmse - poly_rmse > threshold_improvement) || (lin_rmse - exp_rmse > threshold_improvement)
        transitions = [transitions; midpoint_x]; % Record transition at midpoint
    end
end

% Plotting the frequency shifts
subplot(2, 1, 1); % First plot for transitions
plot(x, y, 'b', 'DisplayName', 'Data');
hold on;
plot(transitions, y(ismember(x, transitions)), 'ro', 'DisplayName', 'Transition Points');
xlabel('X');
ylabel('Y');
legend;
title('Transition Points Detection');
grid on;
hold off;

% Plotting confidence levels at midpoints
subplot(2, 1, 2); % Second plot for confidence levels
plot(confidence_data(:,1), confidence_data(:,2) * 100, 'bo-', 'DisplayName', 'Linear Fit Confidence');
hold on;
plot(confidence_data(:,1), confidence_data(:,3) * 100, 'go-', 'DisplayName', 'Polynomial Fit Confidence');
plot(confidence_data(:,1), confidence_data(:,4) * 100, 'ro-', 'DisplayName', 'Exponential Fit Confidence');
xlabel('X (Midpoints of Windows)');
ylabel('Fit Confidence (%)');
title('Fit Confidence Levels Over Time');
legend;
grid on;
hold off;
