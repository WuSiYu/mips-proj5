
module reg32(
  output reg [31:0] D,
  input [31:0] Din,
  input en, clk, rst
);

  parameter reset_val = 32'b0;

  always @ (posedge clk or posedge rst)
    if (rst) D <= reset_val;
    else if (en) D <= Din;

endmodule
