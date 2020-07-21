// device 0~7 addr: 0x00007800 ~ 0x00007fff
// 256 Byte pre device

// IO_hub8 IO_hub8_(soc_out, soc_in, soc_addr, dev_in, dev_addr, dev0_we, dev1_we, dev2_we, dev3_we, dev4_we, dev5_we, dev6_we, dev7_we, dev0_out, dev1_out, dev2_out, dev3_out, dev4_out, dev5_out, dev6_out, dev7_out);
module IO_hub8 (
  input [31:0] soc_out,
  output reg [31:0] soc_in,
  input [31:0] soc_addr,
  input bus_we,

  output [31:0] dev_in,
  output [7:0] dev_addr,
  output dev0_we, dev1_we, dev2_we, dev3_we, dev4_we, dev5_we, dev6_we, dev7_we,
  input [31:0] dev0_out, dev1_out, dev2_out, dev3_out, dev4_out, dev5_out, dev6_out, dev7_out
);

  // device write enable
  reg [7:0] decoder8;
  assign {dev7_we, dev6_we, dev5_we, dev4_we, dev3_we, dev2_we, dev1_we, dev0_we} = (bus_we & soc_addr[31:12] == 20'h00007 & soc_addr[11]) ? decoder8 : 8'b0;
  integer i;
  always @ (*)
    for (i = 0; i < 8; i = i + 1) begin
      decoder8[i] = (soc_addr[10:8] == i);
    end
    
  
  // device uplink
  always @ (*)
    case (soc_addr[10:8])
      3'd0: soc_in = dev0_out;
      3'd1: soc_in = dev1_out;
      3'd2: soc_in = dev2_out;
      3'd3: soc_in = dev3_out;
      3'd4: soc_in = dev4_out;
      3'd5: soc_in = dev5_out;
      3'd6: soc_in = dev6_out;
      3'd7: soc_in = dev7_out;
    endcase


  // device downlink
  assign dev_in = soc_out;

  // device addr
  assign dev_addr = soc_addr[7:0];

endmodule
