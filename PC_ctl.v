// PC Controller(s)

// PC_ctl PC_ctl_(PC_next, PC_addr, ins, reg_in, func, branch_result);
module PC_ctl(
  output reg [31:0] PC_next,
  input [31:0] PC_addr, ins, reg_in,
  input [1:0] func, // 00: +4, 01: branch, 10: jmp_imm, 11: jmp_reg
  input branch_result
);

  always @ (*)
    case (func)
      2'b00: PC_next = PC_addr;   // +4 done in pipeline, do nothing here
      2'b01: PC_next = branch_result ? ({{16{ins[15]}}, ins[15:0]} << 2) + PC_addr : PC_addr;   // As design, branch will not +4 here, it should be done in FETCH stage
      2'b10: PC_next = {PC_addr[31:28], ins[25:0], 2'b0};
      2'b11: PC_next = reg_in;
    endcase


endmodule
