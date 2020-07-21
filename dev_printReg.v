// Debug device: printReg
// write value to device will be displayed in Transcript

// dev dev_(dev_out, dev_in, dev_addr, we, clk, rst);
module dev_printReg(
  output [31:0] dev_out,
  input [31:0] dev_in,
  input [7:0] dev_addr,
  input we, clk, rst
);
  
  always @ (posedge clk)
    if (we) $display("[%0t] [dev_printReg] addr 0x%2X recv value: 0x%8X", $time, dev_addr, dev_in);

endmodule
