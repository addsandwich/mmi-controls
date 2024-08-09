import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import sys 
import threading
from tkinter import StringVar
import yaml
import os
import time

sys.path.insert(1, '../')

from mixers import multimix

class MultiMix3DControllerGUI:

    def __init__(self, client_addr, client_port=48010, debug=False, yaml_file_path='./indicators.yaml'):

        # Multi Mix Object
        self.mx = multimix.MultiMix3D(client_addr, client_port, debug=debug)

        # Runtime Params
        self.messaging_thread = ''
        self.indc_thread = ''
        self.messaging_run = False
        self.debug = debug

        # Indicators
        self.indicators = {}
        self.indicators_conf = {}

        self.load_yaml(yaml_file_path)

        # Create main window
        self.root = tk.Tk()
        self.root.title("MultiMix3D Control Panel")
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.indicators_frame = ''

        # Create Styles
        self.style = ttk.Style()
        self.style.configure("Red.TLabel", foreground="red")
        self.style.configure("Green.TLabel", foreground="green")

        # Messaging Status
        self.connect_stat = StringVar()
        self.connect_stat.set(f'Connected: {self.mx.connected}')

        # Messaging Status
        self.msg_stat = StringVar()
        self.msg_stat.set(f'Messaging On: {self.messaging_run}')
        
        # Heartbeat Status
        self.heartbeat_stat = StringVar()
        self.heartbeat_stat.set(f'Heartbeat On: {not self.mx.mixer_shutdown}')

                # Heartbeat Status
        self.auto_stat = StringVar()
        self.auto_stat.set(f'Automatic On: {not self.mx.auto_shutdown}')

        # Graphical Elements
        self.info_elements = {}

        self.create_window()

    def load_yaml(self, yaml_file_path):
        try:
            # Check if the YAML file exists at the specified path
            if not os.path.isfile(yaml_file_path):
                raise FileNotFoundError(f"YAML file not found at '{yaml_file_path}'")

            # Load and process the YAML configuration
            with open(yaml_file_path, 'r', encoding='utf-8') as file:
                config_data = yaml.safe_load(file)

                # Assuming the YAML contains server_node properties
                if 'indicators' in config_data:
                    for indicator in list(config_data['indicators'].keys()):
                        self.indicators_conf[config_data['indicators'][indicator]['NAME']] = config_data['indicators'][indicator]
                else:
                    raise Exception('indicators not defined in given yaml.')

        except FileNotFoundError as e:
            # Handle the exception if the file is not found
            print(f"Error: {e}")
            # raise

        except yaml.YAMLError as e:
            # Handle YAML parsing errors if the file is not a valid YAML
            print(f"Error parsing YAML: {e}")
            # raise

    def add_text(self):

        while self.messaging_run:
            if self.mx.messaging_queue.qsize() > 0:
                text = self.mx.messaging_queue.get()
            
                self.info_elements["info_text"].config(state=tk.NORMAL)  # Allow editing
                self.info_elements["info_text"].insert(tk.END, text + "\n\n")
                self.info_elements["info_text"].config(state=tk.DISABLED)  # Disable editing after insertion
                self.info_elements["info_text"].see("end")

    def run_text(self):

        if self.messaging_run:
            self.messaging_run = False
            self.messaging_thread.join()
            self.info_elements["messaging_indicator"].config(style="Red.TLabel")
        else:
            self.messaging_run = True
            self.messaging_thread = threading.Thread(target=self.add_text)
            self.messaging_thread.daemon = True
            self.messaging_thread.start()
            self.info_elements["messaging_indicator"].config(style="Green.TLabel")
        self.msg_stat.set(f'Messaging On: {self.messaging_run}')

    def clear_text(self):

        self.info_elements["info_text"].config(state=tk.NORMAL)
        self.info_elements["info_text"].delete(1.0, tk.END)
        self.info_elements["info_text"].config(state=tk.DISABLED)

    def toggle_heartbeat_command(self):

        self.mx.toggle_heartbeat()
        self.heartbeat_stat.set(f'Heartbeat On: {not self.mx.mixer_shutdown}')
        if self.mx.mixer_shutdown:
            self.info_elements["heartbeat_indicator"].config(style="Red.TLabel")
        else:
            self.info_elements["heartbeat_indicator"].config(style="Green.TLabel")

    def toggle_auto_command(self):

        self.mx.toggle_auto()
        self.auto_stat.set(f'Automatic On: {not self.mx.auto_shutdown}')
        if self.mx.mixer_shutdown:
            self.info_elements["auto_indicator"].config(style="Red.TLabel")
        else:
            self.info_elements["auto_indicator"].config(style="Green.TLabel")

    def toggle_connect(self):

        if self.mx.connected:
            self.mx.disconnect()
            self.indc_thread = ''
            time.sleep(1)
            self.run_indc_update()
        else:
            self.mx.connect()
            time.sleep(.2)
            self.indc_thread = threading.Thread(target=self.run_indc_update)
            self.indc_thread.daemon = True
            self.indc_thread.start()

        if self.mx.connected:
            self.info_elements["connected_indicator"].config(style="Green.TLabel")
        else:
            self.info_elements["connected_indicator"].config(style="Red.TLabel")

        self.connect_stat.set(f'Connected: {self.mx.connected}')

    def create_indicator(self, indicator_name, units="", editable=False):

        row = len(self.indicators.keys())

        # Initialize Value
        self.indicators[indicator_name] = "NONE"

        # Entry label for Messaging Indicator
        self.indicators[indicator_name] = StringVar()
        self.indicators[indicator_name].set(f'{0} {units}')
        temp_label = ttk.Label(self.indicators_frame, text=indicator_name, width=18)
        temp_label.grid(row=row, column=0, padx=5)

        # Entry widget for Messaging Indicator
        self.info_elements[indicator_name] = ttk.Label(self.indicators_frame, textvariable=self.indicators[indicator_name], width=18)
        self.info_elements[indicator_name].config(style="Red.TLabel")
        self.info_elements[indicator_name].grid(row=row, column=1, padx=8, pady=5)

    def on_closing(self):
        if messagebox.askokcancel("Quit", "Do you want to quit?"):
            self.mx.disconnect()
            self.mx.mixer_shutdown = True
            self.messaging_run = False
            self.root.destroy()

    def run_indc_update(self):
        while self.mx.connected:
            i = 0
            for key in self.indicators.keys():
                index = self.indicators_conf[key]["NODE_IDX"]
                if not self.mx.connected:
                    break
                temp = self.mx.get_value(index)

                temp_num = str(self.indicators_conf[key]["UNITS"])

                # Entry for Indicator
                self.indicators[key].set(f'{temp} {temp_num}')

                # Entry widget for Messaging Indicator
                self.info_elements[key].config(style="Green.TLabel")

        if not self.mx.connected:
            for key in self.indicators.keys():
                # Change Indicator to Red
                self.info_elements[key].config(style="Red.TLabel")

    
    def create_window(self):

        # Frame to hold the buttons
        self.indicators_frame = ttk.Frame(self.root)
        self.indicators_frame.pack(side = tk.LEFT, padx=10, pady=10, fill=tk.X)

        for indc in self.indicators_conf.keys():
            temp = self.indicators_conf[indc]
            self.create_indicator(temp["NAME"], units=temp["UNITS"])    

        # Frame to hold the scrollable text area (info pane)
        info_frame = ttk.Frame(self.root)
        info_frame.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

        # Scrollbar for the info text
        scrollbar = ttk.Scrollbar(info_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Text widget to display information (info pane)
        self.info_elements["info_text"] = tk.Text(info_frame, wrap=tk.WORD, yscrollcommand=scrollbar.set, state=tk.DISABLED)
        self.info_elements["info_text"].pack(fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.info_elements["info_text"].yview)

        # Frame to hold the command entry and execute button
        command_frame = ttk.Frame(self.root)
        command_frame.pack(side = tk.LEFT, padx=10, pady=10, fill=tk.X)

        # Button to show messaging text to the info pane
        msg_button = ttk.Button(command_frame, text="Toggle Messaging", command=self.run_text)
        msg_button.grid(row=0, column=0, padx=8)

        # Button to toggle the connection
        connection_button = ttk.Button(command_frame, text="Connection Toggle", command=self.toggle_connect)
        connection_button.grid(row=0, column=1, padx=8)

        # Button to toggle the heartbeat
        heartbeat_button = ttk.Button(command_frame, text="Heartbeat Toggle", command=self.toggle_heartbeat_command)
        heartbeat_button.grid(row=0, column=2, padx=8)

        # Button to toggle the auto mode
        automatic_button = ttk.Button(command_frame, text="Automatic Toggle", command=self.toggle_auto_command)
        automatic_button.grid(row=0, column=3, padx=8)


        # Entry widget for Messaging Indicator
        self.info_elements["messaging_indicator"] = ttk.Label(command_frame, textvariable=self.msg_stat, width=18)
        self.info_elements["messaging_indicator"].config(style="Red.TLabel")
        self.info_elements["messaging_indicator"].grid(row=1, column=0, padx=8, pady=5)

        # Entry widget for Messaging Indicator
        self.info_elements["connected_indicator"] = ttk.Label(command_frame, textvariable=self.connect_stat, width=18)
        self.info_elements["connected_indicator"].config(style="Red.TLabel")
        self.info_elements["connected_indicator"].grid(row=1, column=1, padx=8, pady=5)

        # Entry widget for Heartbeat Indicator
        self.info_elements["heartbeat_indicator"] = ttk.Label(command_frame, textvariable=self.heartbeat_stat, width=18)
        self.info_elements["heartbeat_indicator"].config(style="Red.TLabel")
        self.info_elements["heartbeat_indicator"].grid(row=1, column=2, padx=8, pady=5)

        # Entry widget for Automatic Indicator
        self.info_elements["auto_indicator"] = ttk.Label(command_frame, textvariable=self.auto_stat, width=18)
        self.info_elements["auto_indicator"].config(style="Red.TLabel")
        self.info_elements["auto_indicator"].grid(row=1, column=3, padx=8, pady=5)

        # Button to clear the info pane
        clear_button = ttk.Button(command_frame, text="Clear Text", command=self.clear_text)
        clear_button.grid(row=0, column=4, padx=5)

        # Start the Tkinter main loop
        self.root.mainloop()

# Example usage:
if __name__ == "__main__":
    client_addr = "192.168.1.2"
    client_port = "48010"
    MultiMix3DControllerGUI(client_addr, client_port, debug=False)