
// datapath_ctl datapath_ctl_(ALU_B_imm, immExt_sign, GPR_write_PC, GPR_write_MEM, overflow_aware, PC_ctl_func, MEM_data_len, MEM_load_signExt, ALU_func, ins, ins_flags);
module datapath_ctl(
  output ALU_B_imm, immExt_sign, GPR_write_PC, GPR_write_MEM, overflow_aware, output [1:0] PC_ctl_func, MEM_data_len, output MEM_load_signExt,
  output reg [3:0] ALU_func,
  input [31:0] ins,
  input [7:0] ins_flags
);

  wire typeR_ALU, typeR_jr, typeI_ALU, typeI_Branch, typeI_Load, typeI_Store, typeJ, typeCP0_eret;
  assign {typeR_ALU, typeR_jr, typeI_ALU, typeI_Branch, typeI_Load, typeI_Store, typeJ, typeCP0_eret} = ins_flags;

  // datapath control wire
  assign ALU_B_imm = typeI_ALU | typeI_Load | typeI_Store;
  assign immExt_sign = !ins[28]; // addi, addiu, slti, sltiu, lb, lh, lw, sb, sh, sw ...

  assign GPR_write_PC = (typeR_jr & ins[0]) | (typeJ & ins[26]);  // jalr or jal
  assign GPR_write_MEM = typeI_Load;

  assign overflow_aware = (typeR_ALU & (ins[5:0] == 6'b100000))   // add
                        | (ins[31:26] == 6'b001000)               // addi
                        | (typeR_ALU & (ins[5:0] == 6'b100010));  // sub

  assign MEM_data_len = ins[27:26];
  assign MEM_load_signExt = ~ins[28];

  assign PC_ctl_func = 
    typeR_jr      ? 2'b11 :
    typeJ         ? 2'b10 :
    typeI_Branch  ? 2'b01 :
                    2'b00 ;

  // ALU func transcode
  wire [6:0] ALU_func_ROM_addr = {~typeR_ALU, (~typeR_ALU ? ins[31:26] : ins[5:0])};
  always @ (*)
    case (ALU_func_ROM_addr)
      7'h20: ALU_func = 4'h0; // add
      7'h21: ALU_func = 4'h0;
      7'h48: ALU_func = 4'h0;
      7'h49: ALU_func = 4'h0;
      7'b1_100_000: ALU_func = 4'h0; // - lb
      7'b1_100_100: ALU_func = 4'h0; // - lbu
      7'b1_100_001: ALU_func = 4'h0; // - lh
      7'b1_100_101: ALU_func = 4'h0; // - lhu
      7'b1_100_011: ALU_func = 4'h0; // - lw
      7'b1_101_000: ALU_func = 4'h0; // - sb
      7'b1_101_001: ALU_func = 4'h0; // - sh
      7'b1_101_011: ALU_func = 4'h0; // - sw

      7'h22: ALU_func = 4'h1; // sub
      7'h23: ALU_func = 4'h1;

      7'h04: ALU_func = 4'h2; // sllv

      7'h06: ALU_func = 4'h3; // sllr


      7'h24: ALU_func = 4'h4; // and
      7'h4c: ALU_func = 4'h4;

      7'h25: ALU_func = 4'h5; // or
      7'h4d: ALU_func = 4'h5;

      7'h26: ALU_func = 4'h6; // xor
      7'h4e: ALU_func = 4'h6;

      7'h27: ALU_func = 4'h7; // nor


      7'h2a: ALU_func = 4'h8; // less
      7'h4a: ALU_func = 4'h8;

      7'h2b: ALU_func = 4'h9; // less (unsigned)
      7'h4b: ALU_func = 4'h9;

      7'h4f: ALU_func = 4'he; // lui

      default: ALU_func = 4'hf;
    endcase

endmodule

