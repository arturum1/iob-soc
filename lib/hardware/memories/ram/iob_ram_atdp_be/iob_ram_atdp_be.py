def setup(py_params_dict):
    attributes_dict = {
        "original_name": "iob_ram_atdp_be",
        "name": "iob_ram_atdp_be",
        "version": "0.1",
        "generate_hw": False,
        "blocks": [
            {
                "core_name": "iob_ram_atdp",
                "instance_name": "iob_ram_atdp_inst",
            },
        ],
    }

    return attributes_dict