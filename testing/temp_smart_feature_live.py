import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, spectrogram
from scipy.signal.windows import hamming
from datetime import datetime, timedelta
import time
from matplotlib.lines import Line2D
from matplotlib.artist import Artist

# Load CSV file
data = pd.read_csv('Experiment-3-Pump.csv')
threshold = -20
start = 1550
end = -1

# Convert the time column (assuming it's the first column) to datetime
time_utc = pd.to_datetime(data.iloc[start:end, 1], format='%Y-%m-%d %H:%M:%S.%f')  # Adjust format if needed
signal = data.iloc[start:end, 42].values  # Assuming the signal is in column 43

# Convert datetime to seconds relative to the first timestamp (for interpolation)
time_seconds = (time_utc - time_utc.iloc[0]).dt.total_seconds()
new_time_seconds = np.arange(time_seconds.min(), time_seconds.max(), 2)  # Regular 2-second intervals
interpolated_signal = np.interp(new_time_seconds, time_seconds, signal)

# High-pass filter with cutoff frequency of 0.01 Hz
cutoff_frequency = 0.002
Fs = 1 / 2  # Sampling frequency (1 sample every 2 seconds)
b, a = butter(4, cutoff_frequency / (Fs / 2), 'high')
filtered_signal = filtfilt(b, a, interpolated_signal)

# Convert new time array back to UTC for plotting
new_time_utc = [time_utc.iloc[0] + timedelta(seconds=int(s)) for s in new_time_seconds]

# Apply STFT to the filtered signal
f, t, Sxx = spectrogram(filtered_signal, fs=Fs, window=hamming(128), nperseg=128, noverlap=120)

# Convert power to dB
p_db = 10 * np.log10(np.abs(Sxx))

# Create a separate time array for the spectrogram
t_utc = [new_time_utc[round(ti * Fs)] for ti in t]

# Define frequency range of interest
freq_range = (f >= 0.05) & (f <= 0.25)
avg_power = p_db[freq_range, :].mean(axis=0)

# Create a time array for the average power plot
avg_power_time = [new_time_utc[round(ti * Fs)] for ti in t]

# Set up plot
fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 10))

plt.subplots_adjust(hspace=0.5)

# Initialize line plots
line1, = ax1.plot([], [], 'b')
line2, = ax2.plot([], [], 'r')
ax1.set_title('Interpolated Signal Over Time')
ax1.set_xlabel('Time (UTC)')
ax1.set_ylabel('Tempurature (C)')
ax1.grid(True)

ax2.set_title('Average Power in Frequency Range (0.05 - 0.25 Hz)')
ax2.set_xlabel('Time (UTC)')
ax2.set_ylabel('Average Power (dB)')
ax2.grid(True)

# Initialize spectrogram plot with correct shapes
t_mesh, f_mesh = np.meshgrid(t_utc, f)
img = ax3.pcolormesh(t_mesh, f_mesh, p_db, shading='gouraud', cmap='viridis')
img.set_array(p_db.ravel())
ax3.set_xlim(t_utc[0], t_utc[1])
ax3.set_ylim(f[0], f[-1])
ax3.set_title('Spectrogram - Frequency Change Over Time')
ax3.set_xlabel('Time (UTC)')
ax3.set_ylabel('Frequency (Hz)')
fig.colorbar(img, ax=ax3)

differential = int(len(new_time_utc) / len(avg_power_time))
window_size = 500  # Number of points to display in the moving window

# Real-time update loop
for i in range(1, len(new_time_utc)):
    # Determine the start index for the window
    start_idx = max(0, i - window_size)
    
    # Update interpolated signal plot
    line1.set_data(new_time_utc[start_idx:i], interpolated_signal[start_idx:i])
    ax1.set_xlim(new_time_utc[start_idx], new_time_utc[i])
    ax1.set_ylim(np.min(interpolated_signal[start_idx:i]), np.max(interpolated_signal[start_idx:i]))

    j = int(i / differential)-8

    # Update average power plot
    if j < len(avg_power) and i % differential == 0 and j > 1:
        line2.set_data(avg_power_time[max(0, j - window_size):j], avg_power[max(0, j - window_size):j])
        ax2.set_xlim(avg_power_time[max(0, j - window_size)], avg_power_time[j])
        ax2.set_ylim(np.min(avg_power[max(0, j - window_size):j]), np.max(avg_power[max(0, j - window_size):j]))

        # Mark detected failure times
        failure_indices = np.where(avg_power[:j] > threshold)[0]
        for failure_idx in failure_indices:
            ax1.axvline(avg_power_time[failure_idx], color='k', linestyle='--', linewidth=2)
            ax2.axvline(avg_power_time[failure_idx], color='k', linestyle='--', linewidth=2)
            ax3.axvline(avg_power_time[failure_idx], color='k', linestyle='--', linewidth=2)

    # Update spectrogram plot
    if j < len(t) and i % differential == 0 and j > 1:
        img.set_array(p_db.ravel())
        ax3.set_xlim(t_utc[max(0, j - window_size)], t_utc[j - 1])
        ax3.set_ylim(f[0], f[-1])

    plt.pause(0.005)  # Adjust pause time as needed

plt.show()
