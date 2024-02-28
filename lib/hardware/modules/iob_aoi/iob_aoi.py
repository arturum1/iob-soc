import os

from iob_module import iob_module

from iob_and import iob_and
from iob_or import iob_or
from iob_inv import iob_inv


class iob_aoi(iob_module):
    def __init__(self):
        super().__init__()
        self.version = "V0.10"
        self.submodule_list = [
            iob_and(),
            iob_or(),
            iob_inv(),
        ]
