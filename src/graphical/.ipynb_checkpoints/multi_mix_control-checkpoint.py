import tkinter as tk
from tkinter import ttk
import sys 
import threading
# import time

sys.path.insert(1, '../')

from mixers import multimix

mx = multimix.MultiMix3D("192.168.1.1")
messaging_thread = ''
messaging_run = False

def add_text():
    global messaging_run
    global messaging_thread

    while messaging_run:
        if mx.messaging_queue.qsize() > 0:
            text = mx.messaging_queue.get()
        
            info_text.config(state=tk.NORMAL)  # Allow editing
            info_text.insert(tk.END, text + "\n\n")
            info_text.config(state=tk.DISABLED)  # Disable editing after insertion

def run_text():
    global messaging_run
    global messaging_thread
    
    if messaging_run:
        messaging_run = False
        messaging_thread.join()
    else:
        messaging_run = True
        messaging_thread = threading.Thread(target=add_text)

def clear_text():
    info_text.config(state=tk.NORMAL)
    info_text.delete(1.0, tk.END)
    info_text.config(state=tk.DISABLED)

def toggle_heartbeat_command():
    text = "Turning on Heartbeat"
    mx.toggle_heartbeat()

    info_text.config(state=tk.NORMAL)  # Allow editing
    info_text.insert(tk.END, text + "\n\n")
    info_text.config(state=tk.DISABLED)  # Disable editing after insertion

# Create main window
root = tk.Tk()
root.title("Tkinter Interface")

# Frame to hold the buttons
button_frame = ttk.Frame(root)
button_frame.pack(pady=10)

# Button to add text to the info pane
add_button = ttk.Button(button_frame, text="Add Text", command=add_text)
add_button.grid(row=0, column=0, padx=5)

# Button to clear the info pane
clear_button = ttk.Button(button_frame, text="Clear Text", command=clear_text)
clear_button.grid(row=0, column=1, padx=5)

# Frame to hold the scrollable text area (info pane)
info_frame = ttk.Frame(root)
info_frame.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

# Scrollbar for the info text
scrollbar = ttk.Scrollbar(info_frame)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

# Text widget to display information (info pane)
info_text = tk.Text(info_frame, wrap=tk.WORD, yscrollcommand=scrollbar.set, state=tk.DISABLED)
info_text.pack(fill=tk.BOTH, expand=True)
scrollbar.config(command=info_text.yview)

# Frame to hold the command entry and execute button
command_frame = ttk.Frame(root)
command_frame.pack(padx=10, pady=10, fill=tk.X)

# Entry widget for command input
command_entry = ttk.Entry(command_frame, width=50)
command_entry.grid(row=0, column=0, padx=5, pady=5)

# Button to execute command
execute_button = ttk.Button(command_frame, text="Execute", command=toggle_heartbeat_command)
execute_button.grid(row=0, column=1, padx=5, pady=5)

# Start the Tkinter main loop
root.mainloop()