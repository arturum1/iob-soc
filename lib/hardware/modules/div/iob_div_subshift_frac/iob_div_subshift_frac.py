import os

from iob_module import iob_module

from iob_reg import iob_reg
from iob_reg_e import iob_reg_e
from iob_div_subshift import iob_div_subshift


class iob_div_subshift_frac(iob_module):
    def __init__(self):
        super().__init__()
        self.version = "V0.10"
        self.submodule_list = [
            # Setup dependencies
            iob_reg(),
            iob_reg_e(),
            iob_div_subshift(),
        ]
