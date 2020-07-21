// Debug device: debug_input
// [addr 0x00] contains some value

// dev dev_(dev_out, dev_in, dev_addr, we, clk, rst);
module dev_debug_input(
  output [31:0] dev_out,
  input [31:0] dev_in,
  input [7:0] dev_addr,
  input we, clk, rst
);
  
  reg [31:0] val;	// will be accessed by testbench
  always @ (posedge rst)
    if (rst) val <= 32'b0;

  assign dev_out = 
    dev_addr == 8'h00 ? val : 32'h_dead_beef;

endmodule


