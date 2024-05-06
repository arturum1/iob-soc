def setup(py_params_dict):
    attributes_dict = {
        "original_name": "iob_ram_sp",
        "name": "iob_ram_sp",
        "version": "0.1",
        "generate_hw": False,
        "blocks": [
            {
                "core_name": "iob_ram_sp",
                "instance_name": "iob_ram_sp_inst",
            },
        ],
    }

    return attributes_dict
