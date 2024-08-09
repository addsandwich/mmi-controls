import serial
import time
from datetime import datetime
import serial.tools.list_ports
import threading

known_devices = []
threads_running = []
lock = threading.Lock()

def scan_ports():
    ports = serial.tools.list_ports.comports()
    return [port.device for port in ports]

def read_from_port(port, baudrate, timeout):
    try:
        with serial.Serial(port, baudrate, timeout=timeout) as ser:
            print(f"Opened port {port} at {baudrate} baud.")
            file = port + '.txt'
            while True:
                if ser.in_waiting > 0:
                    message = ser.readline().decode('utf-8').strip()
                    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    log_message(timestamp, message,file)
                time.sleep(0.1)  # Adjust delay as needed
    except serial.SerialException as e:
        print(f"Error: {e}")

def log_message(timestamp, message, file):
    with open(file, 'a') as file:
        file.write(f"{timestamp},{message}\n")

if __name__ == "__main__":
    try:
        while True:
            ports = scan_ports()
            for port in ports:
                if port not in known_devices:
                    known_devices.append(port.device)
                    temp_thread = threading.Thread(target=read_from_port, args=(port, 9600, 2))
                    temp_thread.daemon = True
                    temp_thread.start()
                    threads_running = temp_thread
    except KeyboardInterrupt:
        print('interrupted!')

    # Configure your COM port settings here
    #port = 'COM3'  # Change to your COM port
    #baudrate = 9600  # Change to your baud rate
    #timeout = 1  # Timeout in seconds
    
    #read_from_port(port, baudrate, timeout)