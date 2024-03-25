from iob_core import iob_core


class iob_and(iob_core):
    def __init__(self, *args, **kwargs):
        self.set_default_attribute("version", "0.1")

        self.create_conf(
            name="W",
            type="P",
            val="21",
            min="1",
            max="32",
            descr="IO width",
        ),

        self.create_port(
            name="a",
            descr="Input port",
            signals=[
                {"name": "a", "width": "W", "direction": "input"},
            ],
        )
        self.create_port(
            name="b",
            descr="Input port",
            signals=[
                {"name": "b", "width": "W", "direction": "input"},
            ],
        )
        self.create_port(
            name="y",
            descr="Output port",
            signals=[
                {"name": "y", "width": "W", "direction": "output"},
            ],
        )

        self.insert_verilog(
            """
   assign y_o = a_i & b_i;
            """
        )

        super().__init__(*args, **kwargs)
