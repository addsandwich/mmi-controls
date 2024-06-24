import ipaddress

def is_valid_ip_address(ip_str):
    # Check if the IP address is not empty
    if not ip_str:
        print("IP address cannot be empty")
        return False
    
    # Check if the IP address is valid
    try:
        ipaddress.ip_address(ip_str)
        print(f"{ip_str} is a valid IP address")
        return True
    except ValueError:
        print(f"{ip_str} is not a valid IP address")
        return False
    

def is_valid_port(port):
    try:
        port_num = int(port)
        if 0 <= port_num <= 65535:
            print(f"{port} is a valid port number")
            return True
        else:
            print(f"{port} is not a valid port number (out of range)")
            return False
    except ValueError:
        print(f"{port} is not a valid port number (not an integer)")
        return False