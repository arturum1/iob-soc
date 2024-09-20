def setup(py_params_dict):
    attributes_dict = {
        "original_name": "axil2iob",
        "name": "axil2iob",
        "version": "0.1",
        "generate_hw": False,
        "ports": [
            {
                "name": "clk_en_rst_s",
                "interface": {
                    "type": "clk_en_rst",
                    "subtype": "slave",
                },
                "descr": "Clock, clock enable and reset",
            },
            {
                "name": "axil_s",
                "interface": {
                    "type": "axil",
                    "subtype": "slave",
                },
                "descr": "AXIL interface",
            },
            {
                "name": "iob_m",
                "interface": {
                    "type": "iob",
                    "subtype": "master",
                },
                "descr": "CPU native interface",
            },
        ],
        "blocks": [
            {
                "core_name": "iob_reg_e",
                "instance_name": "iob_reg_e_inst",
            },
        ],
    }

    return attributes_dict
