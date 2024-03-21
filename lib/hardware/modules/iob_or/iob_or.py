from iob_module import iob_module


class iob_or(iob_module):
    def __init__(self, *args, **kwargs):
        self.version = "V0.10"

        self.create_conf(
            name="W",
            type="P",
            val="21",
            min="1",
            max="32",
            descr="IO width",
        ),
        self.create_conf(
            name="N",
            type="P",
            val="21",
            min="1",
            max="32",
            descr="Number of inputs",
        ),

        self.create_port(
            name="inputs",
            descr="Inputs port",
            signals=[
                {"name": "in", "width": "N*W", "direction": "input"},
            ]
        )
        self.create_port(
            name="output",
            descr="Output port",
            signals=[
                {"name": "out", "width": "W", "direction": "output"},
            ]
        )

        self.create_wire(
            name="or_vector",
            descr="Logic vector",
            signals=[
                {"name": "or_vec", "width": "N*W"},
            ],
        )

        self.insert_verilog(
            """
   assign or_vec[0 +: W] = in_i[0 +: W];

   genvar i;
   generate
      for (i = 1; i < N; i = i + 1) begin : gen_mux
         assign or_vec[i*W +: W] = in_i[i*W +: W] | or_vec[(i-1)*W +: W];
      end
   endgenerate

   assign out_o = or_vec[(N-1)*W +: W];
            """
        )

        super().__init__(*args, **kwargs)
