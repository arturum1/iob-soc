`timescale 1 ns / 1 ps

`include "bsp.vh"
`include "iob_soc_conf.vh"
`include "iob_soc.vh"
`include "iob_lib.vh"

//Peripherals _swreg_def.vh file includes.
`include "iob_soc_periphs_swreg_def.vs"

module iob_soc #(
   `include "iob_soc_params.vs"
) (
   `include "iob_soc_io.vs"
);

   localparam integer Bbit = `IOB_SOC_B;
   localparam integer AddrMsb = `REQ_W - 2;

   `include "iob_soc_pwires.vs"

   //
   // SYSTEM RESET
   //

   wire boot;
   wire cpu_reset;

   wire cke_i;
   assign cke_i = 1'b1;

   //
   //  CPU
   //

   // instruction bus
   wire [ `REQ_W-1:0] cpu_i_req;
   wire [`RESP_W-1:0] cpu_i_resp;

   // data cat bus
   wire [ `REQ_W-1:0] cpu_d_req;
   wire [`RESP_W-1:0] cpu_d_resp;

   //instantiate the cpu
   iob_picorv32 #(
      .ADDR_W        (ADDR_W),
      .DATA_W        (DATA_W),
      .N_PERIPHERALS (`IOB_SOC_N_SLAVES + 1),
      .USE_COMPRESSED(`IOB_SOC_USE_COMPRESSED),
      .USE_MUL_DIV   (`IOB_SOC_USE_MUL_DIV),
`ifdef IOB_SOC_USE_EXTMEM
      .USE_EXTMEM    (1)
`else
      .USE_EXTMEM    (0)
`endif
   ) cpu (
      .clk_i(clk_i),
      .rst_i(cpu_reset),
      .cke_i(cke_i),
      .boot (boot),
      .trap (trap_o[1]),

      //instruction bus
      .ibus_req (cpu_i_req),
      .ibus_resp(cpu_i_resp),

      //data bus
      .dbus_req (cpu_d_req),
      .dbus_resp(cpu_d_resp)
   );


   //
   // SPLIT CPU BUSES TO ACCESS INTERNAL OR EXTERNAL MEMORY
   //

   //internal memory instruction bus
   wire [ `REQ_W-1:0] int_mem_i_req;
   wire [`RESP_W-1:0] int_mem_i_resp;
   //external memory instruction bus
`ifdef IOB_SOC_USE_EXTMEM
   wire [ `REQ_W-1:0] ext_mem_i_req;
   wire [`RESP_W-1:0] ext_mem_i_resp;

   // INSTRUCTION BUS
   iob_split #(
      .ADDR_W  (ADDR_W),
      .DATA_W  (DATA_W),
      .N_SLAVES(2),
      .P_SLAVES(AddrMsb)
   ) ibus_split (
      .clk_i   (clk_i),
      .arst_i  (cpu_reset),
      // master interface
      .m_req_i (cpu_i_req),
      .m_resp_o(cpu_i_resp),
      // slaves interface
      .s_req_o ({ext_mem_i_req, int_mem_i_req}),
      .s_resp_i({ext_mem_i_resp, int_mem_i_resp})
   );
`else
   assign int_mem_i_req = cpu_i_req;
   assign cpu_i_resp    = int_mem_i_resp;
`endif


   // DATA BUS

   //internal data bus
   wire [ `REQ_W-1:0] int_d_req;
   wire [`RESP_W-1:0] int_d_resp;
`ifdef IOB_SOC_USE_EXTMEM
   //external memory data bus
   wire [ `REQ_W-1:0] ext_mem_d_req;
   wire [`RESP_W-1:0] ext_mem_d_resp;

   iob_split #(
      .ADDR_W  (ADDR_W),
      .DATA_W  (DATA_W),
      .N_SLAVES(2),          //E,{P,I}
      .P_SLAVES(AddrMsb)
   ) dbus_split (
      .clk_i   (clk_i),
      .arst_i  (cpu_reset),
      // master interface
      .m_req_i (cpu_d_req),
      .m_resp_o(cpu_d_resp),
      // slaves interface
      .s_req_o ({ext_mem_d_req, int_d_req}),
      .s_resp_i({ext_mem_d_resp, int_d_resp})
   );
`else
   assign int_d_req  = cpu_d_req;
   assign cpu_d_resp = int_d_resp;
`endif

   //
   // SPLIT INTERNAL MEMORY AND PERIPHERALS BUS
   //

   //slaves bus (includes internal memory + periphrals)
   wire [ (`IOB_SOC_N_SLAVES+1)*`REQ_W-1:0] slaves_req;
   wire [(`IOB_SOC_N_SLAVES+1)*`RESP_W-1:0] slaves_resp;

   iob_split #(
      .ADDR_W  (ADDR_W),
      .DATA_W  (DATA_W),
      .N_SLAVES(`IOB_SOC_N_SLAVES + 1),
      .P_SLAVES(AddrMsb-1)
   ) pbus_split (
      .clk_i   (clk_i),
      .arst_i  (cpu_reset),
      // master interface
      .m_req_i (int_d_req),
      .m_resp_o(int_d_resp),
      // slaves interface
      .s_req_o (slaves_req),
      .s_resp_i(slaves_resp)
   );


   //
   // INTERNAL SRAM MEMORY
   //

   int_mem #(
      .ADDR_W        (ADDR_W),
      .DATA_W        (DATA_W),
      .HEXFILE       ("iob_soc_firmware"),
      .BOOT_HEXFILE  ("iob_soc_boot"),
      .SRAM_ADDR_W   (SRAM_ADDR_W),
      .BOOTROM_ADDR_W(BOOTROM_ADDR_W),
      .B_BIT         (`B_BIT)
   ) int_mem0 (
      .clk_i    (clk_i),
      .arst_i   (arst_i),
      .cke_i    (cke_i),
      .boot     (boot),
      .cpu_reset(cpu_reset),

      // instruction bus
      .i_req (int_mem_i_req),
      .i_resp(int_mem_i_resp),

      //data bus
      .d_req (slaves_req[0+:`REQ_W]),
      .d_resp(slaves_resp[0+:`RESP_W])
   );

`ifdef IOB_SOC_USE_EXTMEM
   //
   // EXTERNAL DDR MEMORY
   //

   wire [ 1+SRAM_ADDR_W-2+DATA_W+DATA_W/8-1:0] ext_mem0_i_req;
   wire [1+MEM_ADDR_W+1-2+DATA_W+DATA_W/8-1:0] ext_mem0_d_req;

   assign ext_mem0_i_req = {
      ext_mem_i_req[`AVALID(0)],
      ext_mem_i_req[`ADDRESS(0, `IOB_SOC_SRAM_ADDR_W)-2],
      ext_mem_i_req[`WRITE(0)]
   };
   assign ext_mem0_d_req = {
      ext_mem_d_req[`AVALID(0)],
      ext_mem_d_req[`ADDRESS(0, MEM_ADDR_W+1)-2],
      ext_mem_d_req[`WRITE(0)]
   };

   // Create bus that contains the highest bit of MEM_ADDR_W and other higher bits up to AXI_ADDR_W.
   wire [AXI_ADDR_W-MEM_ADDR_W:0] axi_higher_araddr_bits;
   wire [AXI_ADDR_W-MEM_ADDR_W:0] axi_higher_awaddr_bits;
   // Invert highest bit of MEM_ADDR_W. Leave all higher bits unaltered.
   assign axi_araddr_o[AXI_ADDR_W+MEM_ADDR_W-1] = ~axi_higher_araddr_bits[0];
   assign axi_awaddr_o[AXI_ADDR_W+MEM_ADDR_W-1] = ~axi_higher_awaddr_bits[0];
   generate
      if ((AXI_ADDR_W - MEM_ADDR_W) > 0) begin : axi_higher_bits
         assign axi_araddr_o[AXI_ADDR_W+MEM_ADDR_W+:AXI_ADDR_W-MEM_ADDR_W] = axi_higher_araddr_bits[1+:AXI_ADDR_W-MEM_ADDR_W];
         assign axi_awaddr_o[AXI_ADDR_W+MEM_ADDR_W+:AXI_ADDR_W-MEM_ADDR_W] = axi_higher_awaddr_bits[1+:AXI_ADDR_W-MEM_ADDR_W];
      end
   endgenerate

   ext_mem #(
      .ADDR_W     (ADDR_W),
      .DATA_W     (DATA_W),
      .FIRM_ADDR_W(SRAM_ADDR_W),
      .MEM_ADDR_W (MEM_ADDR_W),
      .DDR_ADDR_W (`DDR_ADDR_W),
      .DDR_DATA_W (`DDR_DATA_W),
      .AXI_ID_W   (AXI_ID_W),
      .AXI_LEN_W  (AXI_LEN_W),
      .AXI_ADDR_W (AXI_ADDR_W),
      .AXI_DATA_W (AXI_DATA_W)
   ) ext_mem0 (
      // instruction bus
      .i_req (ext_mem0_i_req),
      .i_resp(ext_mem_i_resp),

      //data bus
      .d_req (ext_mem0_d_req),
      .d_resp(ext_mem_d_resp),

      //AXI INTERFACE
      //address write
      .axi_awid_o   (axi_awid_o[2*(AXI_ID_W)-1:AXI_ID_W]),
      .axi_awaddr_o ({axi_higher_awaddr_bits, axi_awaddr_o[AXI_ADDR_W+:MEM_ADDR_W-1]}),
      .axi_awlen_o  (axi_awlen_o[2*(7+1)-1:7+1]),
      .axi_awsize_o (axi_awsize_o[2*(2+1)-1:2+1]),
      .axi_awburst_o(axi_awburst_o[2*(1+1)-1:1+1]),
      .axi_awlock_o (axi_awlock_o[2*(1+1)-1:1+1]),
      .axi_awcache_o(axi_awcache_o[2*(3+1)-1:3+1]),
      .axi_awprot_o (axi_awprot_o[2*(2+1)-1:2+1]),
      .axi_awqos_o  (axi_awqos_o[2*(3+1)-1:3+1]),
      .axi_awvalid_o(axi_awvalid_o[2*(0+1)-1:0+1]),
      .axi_awready_i(axi_awready_i[2*(0+1)-1:0+1]),
      //write
      .axi_wdata_o  (axi_wdata_o[2*(AXI_DATA_W-1+1)-1:AXI_DATA_W-1+1]),
      .axi_wstrb_o  (axi_wstrb_o[2*(AXI_DATA_W/8-1+1)-1:AXI_DATA_W/8-1+1]),
      .axi_wlast_o  (axi_wlast_o[2*(0+1)-1:0+1]),
      .axi_wvalid_o (axi_wvalid_o[2*(0+1)-1:0+1]),
      .axi_wready_i (axi_wready_i[2*(0+1)-1:0+1]),
      //write response
      .axi_bid_i    (axi_bid_i[2*(AXI_ID_W)-1:AXI_ID_W]),
      .axi_bresp_i  (axi_bresp_i[2*(1+1)-1:1+1]),
      .axi_bvalid_i (axi_bvalid_i[2*(0+1)-1:0+1]),
      .axi_bready_o (axi_bready_o[2*(0+1)-1:0+1]),
      //address read
      .axi_arid_o   (axi_arid_o[2*(AXI_ID_W)-1:AXI_ID_W]),
      .axi_araddr_o ({axi_higher_araddr_bits, axi_araddr_o[AXI_ADDR_W+:MEM_ADDR_W-1]}),
      .axi_arlen_o  (axi_arlen_o[2*(7+1)-1:7+1]),
      .axi_arsize_o (axi_arsize_o[2*(2+1)-1:2+1]),
      .axi_arburst_o(axi_arburst_o[2*(1+1)-1:1+1]),
      .axi_arlock_o (axi_arlock_o[2*(1+1)-1:1+1]),
      .axi_arcache_o(axi_arcache_o[2*(3+1)-1:3+1]),
      .axi_arprot_o (axi_arprot_o[2*(2+1)-1:2+1]),
      .axi_arqos_o  (axi_arqos_o[2*(3+1)-1:3+1]),
      .axi_arvalid_o(axi_arvalid_o[2*(0+1)-1:0+1]),
      .axi_arready_i(axi_arready_i[2*(0+1)-1:0+1]),
      //read
      .axi_rid_i    (axi_rid_i[2*(AXI_ID_W)-1:AXI_ID_W]),
      .axi_rdata_i  (axi_rdata_i[2*(AXI_DATA_W-1+1)-1:AXI_DATA_W-1+1]),
      .axi_rresp_i  (axi_rresp_i[2*(1+1)-1:1+1]),
      .axi_rlast_i  (axi_rlast_i[2*(0+1)-1:0+1]),
      .axi_rvalid_i (axi_rvalid_i[2*(0+1)-1:0+1]),
      .axi_rready_o (axi_rready_o[2*(0+1)-1:0+1]),

      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(cpu_reset)
   );
`endif

   `include "iob_soc_periphs_inst.vs"

endmodule
