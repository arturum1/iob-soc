import os

from iob_module import iob_module

from iob_ram_2p import iob_ram_2p


class iob_ram_2p_tiled(iob_module):
    def __init__(self):
        super().__init__()
        self.version = "V0.10"
        self.submodule_list = [
            iob_ram_2p(),
        ]
