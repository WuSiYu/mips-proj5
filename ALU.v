
// ALU alu(out, overflow_flag, A, B, func);
module ALU(
  output reg  [31:0] out,
  output overflow_flag,
  input signed [31:0] A, B,
  input [3:0] func
);

  wire signed [32:0] A_B_add = {A[31], A} + {B[31], B};
  wire signed [32:0] A_B_sub = {A[31], A} - {B[31], B};

  always @ (*)
    case (func)
      4'h0: out = A_B_add[31:0];
      4'h1: out = A_B_sub[31:0];
      4'h2: out = A << B;
      4'h3: out = A >> B;

      4'h4: out = A & B;
      4'h5: out = A | B;
      4'h6: out = A ^ B;
      4'h7: out = ~(A | B);

      4'h8: out = {31'b0, A < B};                   // less
      4'h9: out = {31'b0, {1'b0, A} < {1'b0, B}};   // less unsigned

      4'he: out = {B[15:0], 16'b0};

      default: out = 32'h_dead_beef;
    endcase

  assign overflow_flag = ( (A_B_add[32] != A_B_add[31]) & (func == 4'h0) )
                       | ( (A_B_sub[32] != A_B_sub[31]) & (func == 4'h1) );

endmodule
