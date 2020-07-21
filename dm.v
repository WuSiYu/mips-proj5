// DM 12288 Bytes
// dm_12k dm(addr, din, we, clk, dout);
module dm_12k(
  input [13:0] addr,
  input [31:0] din,  // 32-bit input data
  input we,          // memory write enable
  input clk,         // clock
  output [31:0] dout // 32-bit memory output
);

  reg [7:0] dm [12287:0];

  always @ (posedge clk) 
    if (we) begin
      dm[addr+0] <= din[ 7: 0];
      dm[addr+1] <= din[15: 8];
      dm[addr+2] <= din[23:16];
      dm[addr+3] <= din[31:24];
    end

  assign dout = {
    dm[addr+3],
    dm[addr+2],
    dm[addr+1],
    dm[addr+0]
  };

endmodule
