import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, spectrogram
from scipy.signal.windows import hamming
from datetime import datetime, timedelta
import time


# Load CSV file
data = pd.read_csv('Experiment-5-Pump.csv')
threshold = -20

# Convert the time column (assuming it's the first column) to datetime
time_utc = pd.to_datetime(data.iloc[:, 1], format='%Y-%m-%d %H:%M:%S.%f')  # Adjust format if needed
signal = data.iloc[:, 42].values  # Assuming the signal is in column 43

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

# 1st subplot: Plot the interpolated signal
ax1.plot(new_time_utc, interpolated_signal, 'b')
ax1.set_title('Interpolated Signal Over Time')
ax1.set_xlabel('Time (UTC)')
ax1.set_ylabel('Signal')
ax1.grid(True)

# 2nd subplot: Plot average power in the frequency range
ax2.plot(avg_power_time, avg_power, 'r')
ax2.set_title('Average Power in Frequency Range (0.05 - 0.25 Hz)')
ax2.set_xlabel('Time (UTC)')
ax2.set_ylabel('Average Power (dB)')
ax2.grid(True)

# Mark detected failure times
failure_indices = np.where(avg_power > threshold)[0]
for failure_idx in failure_indices:
    ax2.axvline(avg_power_time[failure_idx], color='k', linestyle='--', linewidth=2)
    ax3.axvline(avg_power_time[failure_idx], color='k', linestyle='--', linewidth=2)

# 3rd subplot: Plot the spectrogram
img = ax3.pcolormesh(t_utc, f, p_db, shading='gouraud', cmap='viridis')
ax3.set_title('Spectrogram - Frequency Change Over Time')
ax3.set_xlabel('Time (UTC)')
ax3.set_ylabel('Frequency (Hz)')
fig.colorbar(img, ax=ax3)

plt.tight_layout()
plt.show()