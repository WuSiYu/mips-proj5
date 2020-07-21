// branch_comp branch_comp_(result, A, B, func);
module branch_comp(
  output reg result,  // 1 means should do branch
  input [31:0] A, B,
  input [1:0] func    // 00, 01, 10, 11: beq, bne, blez, bgtz
);

  always @ (*)
    case (func)
      2'b00: result = (A == B);
      2'b01: result = (A != B);
      2'b10: result = |A ? A[31] : 1'b1;
      2'b11: result = |A ? ~A[31] : 1'b0;
    endcase

endmodule
