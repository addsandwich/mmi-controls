import opcua
from opcua.client import client
import sys
import time
import threading
from queue import Queue

sys.path.insert(1, '../')

import lib.helpers as hlp

class MultiMix3D:
    """This class is the object version of the Multi-Mix3D concrete pump."""

    def __init__(self, client_addr, client_port=48010, debug=False):
        """Constructor to initialize starting variables."""

        # Setup Client
        self.opc_start_string = "opc.tcp://"
        self.opcua_cl = ""
        self.debug = debug
        self.sleeptime = .8

        if debug:
            self.sleeptime = 2

        self.connected = False

        self.mixer_shutdown = True

        self.heartbeat_thread = None

        self.messaging_queue_size = 30
        self.messaging_queue = Queue(self.messaging_queue_size)

        if hlp.is_valid_ip_address(client_addr):
            self.client_addr = client_addr
        else:
            raise ValueError(f"{client_addr} is not a valid address.")

        if hlp.is_valid_port(client_port):
            self.client_port = client_port
        else:
            raise ValueError(f"{client_port} is not a valid port number.")

    def connect(self):
        location = "connect"
        if self.debug:
            msg_str = "Not connected. In Debug Mode"
            self.q_insert(msg_str, location, error=1)
        else:
            try:
                temp_client = self.get_client_string()
                self.opcua_cl = client.Client(temp_client)
                self.opcua_cl.connect()
                temp_node = self.opcua_cl.get_objects_node().get_children()[3]
                self.values_node = temp_node.get_children()[0].get_children()
                self.connected = True
                msg_str = f"Successfully connected to {temp_client}"
                self.q_insert(msg_str, location, error=0)

            except TimeoutError as err:
                msg_str = "Couldn't connect. Attempt timed out. "
                msg_str += f"Reported error message:{err}"
                self.q_insert(msg_str, location, error=4)

            except Exception as err:
                msg_str = "Couldn't connect. Something unexpected happened. "
                msg_str += f"Reported error message:{err}"
                self.q_insert(msg_str, location, error=4)

    def disconnect(self):
        location = "disconnect"
        
        try:
            self.opcua_cl.disconnect()
            self.connected = False
            msg_str = f"Successfully disconnected from the MultiMix"
            self.q_insert(msg_str, location, error=0)

        except TimeoutError as err:
            msg_str = "Couldn't disconnect. "
            msg_str += f"Reported error message:{err}"
            self.q_insert(msg_str, location, error=4)

        except Exception as err:
            msg_str = "Couldn't disconnect. Something unexpected happened. "
            msg_str += f"Reported error message:{err}"
            self.q_insert(msg_str, location, error=4)

    def get_client_string(self):
        return f"{self.opc_start_string}{self.client_addr}:{self.client_port}"
    
    def toggle_heartbeat(self):
        location = "toggle_heartbeat"
        
        if self.connected or self.debug:
            try:
                if self.mixer_shutdown:
                    self.mixer_shutdown = False
                    msg_str = "Starting Heartbeat"
                    self.q_insert(msg_str, location)
                    self.heartbeat_thread = threading.Thread(target=self.heartbeat_loop)
                    self.heartbeat_thread.daemon = True
                    self.heartbeat_thread.start()
                    msg_str = "Heartbeat Started"
                    self.q_insert(msg_str, location)
                else:
                    self.stop_heartbeat()
            except KeyboardInterrupt:
                self.stop_heartbeat()
                msg_str = "Keyboard Interrupt"
                self.q_insert(msg_str, location, error=1)
        else:
            msg_str = "You need to connect to the multimix first"
            self.q_insert(msg_str, location, error=1)

    def q_insert(self, msg, location, error=0):

        if self.messaging_queue.qsize() >= self.messaging_queue_size:
            while self.messaging_queue.qsize() > self.messaging_queue_size:
                self.messaging_queue.get()

        q_str = f"Message String:{msg}, Location:{location}, Error:{hlp.error_level[error]}"
        self.messaging_queue.put(q_str)

    def stop_heartbeat(self):
        msg_str = "Stopping Heartbeat"
        location = "stop_heartbeat"
        self.q_insert(msg_str, location)

        self.mixer_shutdown = True
        self.heartbeat_thread.join()
        self.heartbeat_thread = None

    def get_value(self, node_index):
        res = 0
        if self.connected:
            res = self.values_node[node_index].get_data_value().Value.Value
        return res

    def heartbeat_loop(self):
        # hb_value = 'GECO/MPRX_EXT_Heartbeat'
        if not self.debug:
            hb_idx = 33
            heartbeat_variant = self.values_node[hb_idx].get_data_value()
            datavalue = opcua.ua.DataValue(opcua.ua.Variant(True, 
                                                            heartbeat_variant.Value.VariantType), status=None)
        while not self.mixer_shutdown:
            if not self.debug:
                self.values_node[hb_idx].set_attribute(13, datavalue)
            if self.debug:
                msg_str = "Heartbeat Sent"
                location = "heartbeat_loop"
                self.q_insert(msg_str, location)
            time.sleep(self.sleeptime)
        msg_str = "Heartbeat Stopped"
        location = "heartbeat_loop"
        self.q_insert(msg_str, location)


        
