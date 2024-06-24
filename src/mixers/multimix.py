import opcua
from opcua.client import client
import sys

sys.path.insert(1, '../')

import lib.helpers as hlp

class MultiMix3D:
    """This class is the object version of the Multi-Mix3D concrete pump."""

    def __init__(self, client_addr, client_port=48010):
        """Constructor to initialize starting variables."""

        # Setup Client
        self.opc_start_string = "opc.tcp://"
        self.opcua_cl = ""

        if hlp.is_valid_ip_address(client_addr):
            self.client_addr = client_addr
        else:
            raise ValueError(f"{client_addr} is not a valid address.")

        if hlp.is_valid_port(client_port):
            self.client_port = client_port
        else:
            raise ValueError(f"{client_port} is not a valid port number.")

    def connect(self):
        try:
            self.opcua_cl = client.Client(self.get_client_string())
            self.opcua_cl.connect()
            self.att_node = self.opcua_cl.get_objects_node().get_children()[3]
            self.connected = True

        except TimeoutError as err:
            print("Couldn't connect. Attempt timed out.")
            print(f"Reported error message:{err}")
        except Exception as err:
            print("Couldn't connect. Something unexpected happened.")
            print(f"Reported error message:{err}")

    def get_client_string(self):
        return f"{self.opc_start_string}{self.client_addr}:{self.client_port}"


        
