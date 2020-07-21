
module microsystem(
  input clk, rst
);
  
  wire [31:0] bus_downlink, bus_uplink, bus_addr;
  wire bus_we;
  wire [5:0] ext_int;
  mips soc(clk, rst, bus_downlink, bus_uplink, bus_addr, bus_we, ext_int);
  
  wire dev0_we, dev1_we, dev2_we, dev3_we, dev4_we, dev5_we, dev6_we, dev7_we;
  wire [31:0] dev0_out, dev1_out, dev2_out, dev3_out, dev4_out, dev5_out, dev6_out, dev7_out;
  wire [31:0] dev_in;
  wire [7:0] dev_addr;
  IO_hub8 IO_hub8_(bus_downlink, bus_uplink, bus_addr, bus_we, dev_in, dev_addr, 
    dev0_we, dev1_we, dev2_we, dev3_we, dev4_we, dev5_we, dev6_we, dev7_we, 
    dev0_out, dev1_out, dev2_out, dev3_out, dev4_out, dev5_out, dev6_out, dev7_out);
  
  // device #0: 0x00007800 ~ 0x000078ff
  dev_printReg dev_printReg_(dev0_out, dev_in, dev_addr, dev0_we, clk, rst);

  // device #1: 0x00007900 ~ 0x000079ff
  dev_debug_input dev_debug_input_(dev1_out, dev_in, dev_addr, dev1_we, clk, rst);

  // device #2: 0x00007A00 ~ 0x00007Aff
  dev_clk_counter dev_clk_counter_(dev2_out, dev_in, dev_addr, dev2_we, clk, rst);
  
  // device #7: 0x00007F00 ~ 0x00007Fff
  dev_timer dev_timer_(ext_int[0], dev7_out, dev_in, dev_addr, dev7_we, clk, rst);
  
  assign ext_int[5:1] = 0;
  
endmodule
