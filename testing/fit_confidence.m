% Sample data (replace with actual data)
x = linspace(0, 10, 100); 
y = x + 0.5 * x.^2 + 2 * exp(0.1 * x); % Sample with linear, quadratic, and exponential behavior

% Parameters for sliding window analysis
window_size = 20; % Number of points per segment
overlap = 10; % Overlap between windows
num_segments = floor((length(y) - window_size) / (window_size - overlap)) + 1;

% Threshold for detecting change
threshold_improvement = 0.1; % Adjust this value for sensitivity

% Store transition points
transitions = [];

for i = 1:num_segments
    % Define window indices
    start_idx = (i - 1) * (window_size - overlap) + 1;
    end_idx = start_idx + window_size - 1;
    x_seg = x(start_idx:end_idx);
    y_seg = y(start_idx:end_idx);

    % Linear fit
    lin_coeffs = polyfit(x_seg, y_seg, 1);
    y_lin_fit = polyval(lin_coeffs, x_seg);
    lin_rmse = sqrt(mean((y_seg - y_lin_fit).^2));

    % Polynomial fit (order 2)
    poly_coeffs = polyfit(x_seg, y_seg, 2);
    y_poly_fit = polyval(poly_coeffs, x_seg);
    poly_rmse = sqrt(mean((y_seg - y_poly_fit).^2));

    % Exponential fit
    exp_model = fit(x_seg', y_seg', 'exp1');
    y_exp_fit = exp_model(x_seg);
    exp_rmse = sqrt(mean((y_seg - y_exp_fit).^2));

    % Check if polynomial or exponential fit is significantly better
    if (lin_rmse - poly_rmse > threshold_improvement) || (lin_rmse - exp_rmse > threshold_improvement)
        transitions = [transitions; x_seg(1)]; % Record transition start point
    end
end

% Plotting results
plot(x, y, 'b', 'DisplayName', 'Data');
hold on;
plot(transitions, y(ismember(x, transitions)), 'ro', 'DisplayName', 'Transition Points');
xlabel('X');
ylabel('Y');
legend;
title('Transition Points Detection');
grid on;
hold off;