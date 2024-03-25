from dataclasses import dataclass
from typing import Dict, List
from iob_wire import iob_wire, create_wire


@dataclass
class iob_port(iob_wire):
    """Describes an IO port."""

    direction: str = None
    # Module's internal wire that connects this port
    i_connect: iob_wire = None
    # External wire that connects this port
    e_connect: iob_wire = None

    # Prefix for ports generated by 'if_gen'
    port_prefix: str = ""

    def __post_init__(self):
        if not self.direction:
            raise Exception("Port direction is required")
        elif self.direction not in ["input", "output", "inout"]:
            raise Exception("Error: Direction must be 'input', 'output', or 'inout'.")

    def connect_external(self, wire):
        """Connects the port to an external wire"""
        self.e_connect = wire


def create_port(core, *args, **kwargs):
    """Creates a new port object and adds it to the core's port list
    Also creates a new internal module wire to connect to the new port
    param core: core object
    """
    # Ensure 'ports' list exists
    core.set_default_attribute("ports", [])
    create_wire(core, *args, **kwargs)
    wire = core.wires[-1]
    port = iob_port(*args, i_connect=wire, **kwargs)
    core.ports.append(port)
