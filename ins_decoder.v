// Instruction Pre-decoder

// ins_decoder ins_decoder_(reg_R1, reg_R2, reg_W, ins_flags, ins);
module ins_decoder(
  output [4:0] reg_R1, reg_R2, output reg [4:0]reg_W,
  output [7:0] ins_flags,
  input [31:0] ins
);

  wire typeR_ALU, typeR_jr, typeI_ALU, typeI_Branch, typeI_Load, typeI_Store, typeJ, typeCP0_eret;
  assign ins_flags = {typeR_ALU, typeR_jr, typeI_ALU, typeI_Branch, typeI_Load, typeI_Store, typeJ, typeCP0_eret};

  wire typeCP0 = (ins[31:26] == 6'b010000);
  wire typeCP0_mfc0 = typeCP0 & (ins[25:21] == 5'b00000);
  wire typeCP0_mtc0 = typeCP0 & (ins[25:21] == 5'b00100);

  wire typeR = (ins[31:26] == 6'b000000);
  assign typeR_ALU    = typeR & (ins[5:1] != 5'b00100);
  assign typeR_jr     = typeR & ~typeR_ALU;
  assign typeI_ALU    = (ins[31:29] == 3'b001);
  assign typeI_Branch = (ins[31:28] == 4'b0001);
  assign typeI_Load   = (ins[31:29] == 3'b100) | typeCP0_mfc0;
  assign typeI_Store  = (ins[31:29] == 3'b101) | typeCP0_mtc0;
  assign typeJ        = (ins[31:27] == 5'b00001);
  assign typeCP0_eret = (ins == 32'h_42000018);

  assign reg_R1 = (~typeJ) ? ins[25:21] : 5'b0;
  assign reg_R2 = (typeR_ALU | typeI_Store | typeI_Branch) ? ins[20:16] : 5'b0;
  
  always @ (*)
    if (typeI_ALU | typeI_Load) reg_W = ins[20:16];
    else if (typeR) reg_W = ins[15:11];
    else if (typeJ & ins[26]) reg_W = 5'h1f;
    else reg_W = 5'b0;

endmodule
