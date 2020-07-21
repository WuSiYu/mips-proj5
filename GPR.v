// GPR file

// GPR GPR_(R1, R2, W1, reg_R1, reg_R2, reg_W1, set_overflow_bit, en, clk, rst);
module GPR(
  output [31:0] R1, R2,
  input [31:0] W1,
  input [4:0] reg_R1, reg_R2, reg_W1,
  input set_overflow_bit, en, clk, rst
);
  
  reg [31:0] gpr [31:0];

  integer i;
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1)
        gpr [i] <= 32'b0;
    end else begin
      if (en) begin
        if (set_overflow_bit) gpr[5'd30][0] <= 1'b1;
        else if (|reg_W1) gpr[reg_W1] <= W1;
      end
    end
  end

  assign R1 = gpr[reg_R1];
  assign R2 = gpr[reg_R2];

endmodule
