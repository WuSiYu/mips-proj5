// MIPS SoC SubSystem

// mips soc(clk, rst, bus_data_O, bus_data_I, bus_addr, bus_we, _ext_int);
module mips(
  input clk, rst,
  output [31:0] bus_data_O, input [31:0] bus_data_I,
  output [31:0] bus_addr,
  output bus_we,
  input [5:0] _ext_int
);

  //
  // 5 Stage Pipeline MIPS-lite SoC
  // Designed by Wu23333 <wu.siyu@hotmail.com>, Date: 2020.07
  //
  // Supported instructions:
  //    add, addu, addi, addiu, sub, subu, sllv, srlv, and, andi, or, ori, xor, xori, nor, lui, slt, sltu, slti, sltiu,
  //    beq, bne, blez, bgtz, j, jal, jr, jalr,
  //    lb, lbu, lh, lhu, lw, sb, sh, sw, 
  //    mfc0, mtc0, eret
  //
  // Wire's naming conventions (most is):
  //    _*                           - Global connection
  //    _(EXE|MEM|WB)_forward        - Forward source
  //    (FETCH|DECODE|EXE|MEM|WB)_*  - Pipeline gate register output (eg. EXE_ALU_out is the output of E/M register, as one of MEM stage's input)
  //    other                        - Stage interconnection, usually defined near it's signal source module
  //



  // === FETCH ===

  // Next PC (PC_to_lock) front logic
  wire [31:0] PC_addr, _EPC_out, _PC_next, PC_to_lock;
  wire _hazard_lock, _PC_use_PC_ctl;
  wire _ISR_entering, _ISR_leaving;
  assign PC_to_lock = _ISR_entering ? 32'h_0000_4180 :    // NOTICE: All ext int IRQ will jmp to addr 0x00004180
                      _ISR_leaving  ? _EPC_out  :
                      _PC_use_PC_ctl ? _PC_next :
                      _hazard_lock   ? PC_addr  : PC_addr + 4;

  // PC
  reg32 #(32'h_0000_3000) PC_(PC_addr, PC_to_lock, 1'b1, clk, rst);   // NOTICE: PC reset from addr 0x00003000

  // IM
  // NOTICE: addr 0x00003000 ~ 0x00004fff -> IM[0x0000] ~ IM[0x1fff], linear mapping
  // wire [31:0] PC_addr_shift = PC_addr - 32'h_0000_3000;   // NOTICE: <- optimization this line if download to hardware
  wire [31:0] PC_addr_shift = (PC_addr[14:12] == 3'b011) ? {19'b0, 1'b0, PC_addr[11:0]} :
                              (PC_addr[14:12] == 3'b100) ? {19'b0, 1'b1, PC_addr[11:0]} : 32'h_dead_beef;
  wire [12:0] im_addr = PC_addr_shift[12:0];
  wire [31:0] im_dout;
  im_8k IM(im_addr, im_dout);

  // ### POST FETCH ###
  wire [31:0] FETCH_ins;
  reg32 r_FETCH_ins(FETCH_ins, im_dout, ~_hazard_lock, clk, rst);   // if hazard, lock IR
  wire [31:0] FETCH_PC;
  reg32 r_FETCH_PC(FETCH_PC, PC_addr + 4, ~_hazard_lock, clk, rst);  // *_PC in pipeline is "PC + 4"; if hazard, lock FETCH_PC



  // === DECODE STAGE ===

  // Ins. pre-decode
  wire [7:0] ins_flags;
  wire [4:0] reg_R1, reg_R2, reg_W;
  ins_decoder ins_decoder_(reg_R1, reg_R2, reg_W, ins_flags, FETCH_ins);

  // GPR
  wire [31:0] GPR_R1, GPR_R2, _GPR_W;
  wire [4:0] MEM_GPR_reg_w; // next step for MEM is write back (GPR), used at here
  wire _set_overflow_bit;
  GPR GPR_(GPR_R1, GPR_R2, _GPR_W, reg_R1, reg_R2, MEM_GPR_reg_w, _set_overflow_bit, 1'b1, clk, rst);

  // datapath controller
  wire ALU_B_imm, immExt_sign, GPR_write_use_PC, GPR_write_use_MEM, overflow_aware; wire [1:0] PC_ctl_func;
  wire [1:0] MEM_data_len; wire MEM_load_signExt;
  wire [3:0] ALU_func;
  datapath_ctl datapath_ctl_(ALU_B_imm, immExt_sign, GPR_write_use_PC, GPR_write_use_MEM, overflow_aware, PC_ctl_func, MEM_data_len, MEM_load_signExt, ALU_func, FETCH_ins, ins_flags);

  // immExt
  wire [31:0] immExt_out;
  immExt immExt_(immExt_out, FETCH_ins[15:0], immExt_sign);

  // PC & Launch ctl
  wire _IRQ;
  wire branch_result;
  wire [1:0] R1_forward_ctl, R2_forward_ctl;
  wire [4:0] DECODE_GPR_reg_w, EXE_GPR_reg_w;
  wire DECODE_GPR_write_use_MEM, _EXE_has_exception;
  pipeline_launch_ctl pipeline_launch_ctl_(_hazard_lock, ins_flags, R1_forward_ctl, R2_forward_ctl, _PC_use_PC_ctl, branch_result, reg_R1, reg_R2, DECODE_GPR_reg_w, EXE_GPR_reg_w, MEM_GPR_reg_w, DECODE_GPR_write_use_MEM, _EXE_has_exception, _IRQ, _ISR_entering, _ISR_leaving, clk, rst);

  // data forward
  wire [31:0] _EXE_forward, _MEM_forward, _WB_forward;
  reg [31:0] launch_R1, launch_R2;
  always @ (*) begin
    case(R1_forward_ctl)
      2'b00: launch_R1 = GPR_R1;
      2'b01: launch_R1 = _EXE_forward;
      2'b10: launch_R1 = _MEM_forward;
      2'b11: launch_R1 = _WB_forward;
    endcase
    case(R2_forward_ctl)
      2'b00: launch_R2 = GPR_R2;
      2'b01: launch_R2 = _EXE_forward;
      2'b10: launch_R2 = _MEM_forward;
      2'b11: launch_R2 = _WB_forward;
    endcase
  end

  // branch comparator
  branch_comp branch_comp_(branch_result, launch_R1, launch_R2, FETCH_ins[27:26]);  // func 00, 01, 10, 11: beq, bne, blez, bgtz

  // PC controller
  PC_ctl PC_ctl_(_PC_next, FETCH_PC, FETCH_ins, launch_R1, PC_ctl_func, branch_result);

  // ### POST DECODE ###
  wire [31:0] DECODE_ins;
  wire [31:0] launch_ins = (_hazard_lock ? 32'b0 : FETCH_ins);
  reg32 r_DECODE_ins(DECODE_ins, launch_ins, 1'b1, clk, rst);
  wire [31:0] DECODE_PC;
  reg32 r_DECODE_PC(DECODE_PC, FETCH_PC, 1'b1, clk, rst);

  wire [31:0] DECODE_R1, DECODE_R2, DECODE_ALU_B;
  wire [31:0] ALU_B_source = ALU_B_imm ? immExt_out : launch_R2;
  reg32 r_DECODE_R1(DECODE_R1, launch_R1, 1'b1, clk, rst);
  reg32 r_DECODE_R2(DECODE_R2, launch_R2, 1'b1, clk, rst);
  reg32 r_DECODE_ALU_B(DECODE_ALU_B, ALU_B_source, 1'b1, clk, rst);
  
  /*wire [4:0] DECODE_GPR_reg_w;*/ wire DECODE_GPR_write_use_PC, DECODE_overflow_aware; wire [1:0] DECODE_MEM_data_len; wire DECODE_MEM_load_signExt; wire [3:0] DECODE_ALU_func;
  wire [31:0] DECODE_ctrl32;
  wire [4:0] launch_reg_W = (_hazard_lock ? 5'b0 : reg_W);
  reg32 r_DECODE_ctrl(DECODE_ctrl32, {17'b0, launch_reg_W, GPR_write_use_PC, GPR_write_use_MEM, overflow_aware, MEM_data_len, MEM_load_signExt, ALU_func}, 1'b1, clk, rst);
  assign {DECODE_GPR_reg_w, DECODE_GPR_write_use_PC, DECODE_GPR_write_use_MEM, DECODE_overflow_aware, DECODE_MEM_data_len, DECODE_MEM_load_signExt, DECODE_ALU_func} = DECODE_ctrl32[14:0];



  // === EXE STAGE ===

  // ALU
  wire [31:0] ALU_out;
  wire ALU_overflow_flag;
  ALU ALU_(ALU_out, ALU_overflow_flag, DECODE_R1, DECODE_ALU_B, DECODE_ALU_func);

  assign _EXE_has_exception = ALU_overflow_flag & DECODE_overflow_aware;
  assign _EXE_forward = DECODE_GPR_write_use_PC  ? DECODE_PC :
                        DECODE_GPR_write_use_MEM ? 32'h_dead_beef :    // DEBUG: when load_hazard, should never forward from EXE stage
                        /* ALU ins. */             ALU_out;

  // ### POST EXE ###
  wire [31:0] EXE_ins;
  reg32 r_EXE_ins(EXE_ins, DECODE_ins, 1'b1, clk, rst);
  wire [31:0] EXE_PC;
  reg32 r_EXE_PC(EXE_PC, DECODE_PC, 1'b1, clk, rst);

  wire [31:0] EXE_R2;
  reg32 r_EXE_R2(EXE_R2, DECODE_R2, 1'b1, clk, rst);
  wire [31:0] EXE_ALU_out;
  reg32 r_EXE_ALU_out(EXE_ALU_out, ALU_out, 1'b1, clk, rst);
  
  /* wire [4:0] EXE_GPR_reg_w; */ wire EXE_GPR_write_use_PC, EXE_GPR_write_use_MEM, EXE_overflow_aware; wire [1:0] EXE_MEM_data_len; wire EXE_MEM_load_signExt, EXE_ALU_overflow_flag;
  wire [31:0] EXE_ctrl32;
  wire [4:0] next_GPR_reg_w = _EXE_has_exception ? 5'b0 : DECODE_GPR_reg_w;
  reg32 r_EXE_ctrl(EXE_ctrl32, {20'b0, next_GPR_reg_w, DECODE_GPR_write_use_PC, DECODE_GPR_write_use_MEM, DECODE_overflow_aware, DECODE_MEM_data_len, DECODE_MEM_load_signExt, ALU_overflow_flag}, 1'b1, clk, rst);
  assign {EXE_GPR_reg_w, EXE_GPR_write_use_PC, EXE_GPR_write_use_MEM, EXE_overflow_aware, EXE_MEM_data_len, EXE_MEM_load_signExt, EXE_ALU_overflow_flag} = EXE_ctrl32[11:0];



  // === MEM STAGE ===

  // CP0 reg r/w
  wire typeCP0 = (EXE_ins[31:26] == 6'b010000);
  wire typeCP0_mfc0 = typeCP0 & (EXE_ins[25:21] == 5'b00000);
  wire typeCP0_mtc0 = typeCP0 & (EXE_ins[25:21] == 5'b00100);

  wire [31:0] CP0_out;
  wire CP0_we = typeCP0_mtc0;
  CP0 CP0_(CP0_out, EXE_R2, EXE_ins[15:11], _EPC_out, PC_addr, _IRQ, _ISR_entering, _ISR_leaving, _ext_int, CP0_we, clk, rst);

  // DM
  wire is_MEMBUS_Store = (EXE_ins[31:29] == 3'b101);  // save Ins.
  wire internal_DM_sel = (EXE_ALU_out[31:14] == 18'b0) & (EXE_ALU_out[13:12] != 2'b11); // internal DM 0x00000000 ~ 0x00002fff
  wire [13:0] dm_addr;
  wire [31:0] dm_din, dm_dout;
  wire dm_we = internal_DM_sel & is_MEMBUS_Store;
  dm_12k DM(dm_addr, dm_din, dm_we, clk, dm_dout);
  wire [31:0] dm_W_out;
  dm_warpper dm_warpper_(dm_addr, dm_din, dm_dout, dm_W_out, EXE_ALU_out, EXE_R2, EXE_MEM_data_len, EXE_MEM_load_signExt);

  // sys bus
  assign bus_data_O = EXE_R2;
  assign bus_addr   = EXE_ALU_out;
  assign bus_we     = ~internal_DM_sel & is_MEMBUS_Store;

  // MEM stage output sel (DM, bus, CP0)
  wire [31:0] mem_final_sel = 
    typeCP0_mfc0    ? CP0_out  :
    internal_DM_sel ? dm_W_out : bus_data_I;

  assign _MEM_forward = EXE_GPR_write_use_PC  ? EXE_PC :
                        EXE_GPR_write_use_MEM ? mem_final_sel :
                        /* ALU ins. */          EXE_ALU_out;

  // ### POST MEM ###
  wire [31:0] MEM_PC;
  reg32 r_MEM_PC(MEM_PC, EXE_PC, 1'b1, clk, rst);

  wire [31:0] MEM_ALU_out;
  reg32 r_MEM_ALU_out(MEM_ALU_out, EXE_ALU_out, 1'b1, clk, rst);
  wire [31:0] MEM_out;
  reg32 r_MEM_out(MEM_out, mem_final_sel, 1'b1, clk, rst);

  /* wire [4:0] MEM_GPR_reg_w; */ wire MEM_GPR_write_use_PC, MEM_GPR_write_use_MEM, MEM_overflow_aware, MEM_ALU_overflow_flag;
  wire [31:0] MEM_ctrl32;
  reg32 r_MEM_ctrl(MEM_ctrl32, {23'b0, EXE_GPR_reg_w, EXE_GPR_write_use_PC, EXE_GPR_write_use_MEM, EXE_overflow_aware, EXE_ALU_overflow_flag}, 1'b1, clk, rst);
  assign {MEM_GPR_reg_w, MEM_GPR_write_use_PC, MEM_GPR_write_use_MEM, MEM_overflow_aware, MEM_ALU_overflow_flag} = MEM_ctrl32[8:0];


  // === WB STAGE ===

  // Write back logics
  assign _GPR_W =
    MEM_GPR_write_use_PC  ? MEM_PC :
    MEM_GPR_write_use_MEM ? MEM_out :
                            MEM_ALU_out ;   // passthrough from EXE stage

  // NOTICE: GPR $30[0] overflow_bit not support hazard_control / data_forward!
  assign _set_overflow_bit = MEM_overflow_aware & MEM_ALU_overflow_flag;

  assign _WB_forward = _GPR_W;


endmodule
