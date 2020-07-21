
// pipeline_launch_ctl pipeline_launch_ctl_(hazard_lock, ins_prelaunch_flags, R1_forward_ctl, R2_forward_ctl, prelaunch_R1, prelaunch_R2, DECODE_reg_W, EXE_reg_W, MEM_reg_W, DECODE_GPR_write_MEM, IRQ, ISR_entering, ISR_leaving, clk, rst);
module pipeline_launch_ctl(
  output hazard_lock,   // launch pipeline bubble, lock PC auto +4, lock IR (POST FETCH)

  input [7:0] ins_prelaunch_flags,

  output [1:0] R1_forward_ctl, R2_forward_ctl,  // 00 - GPR, 01 - EXE_forward, 10 - MEM_forward, 11 - WB_forward
  output PC_use_PC_ctl,   // when = 1, PC use PC_ctl val (for branch/jmp, hazard_lock needed)

  input branch_result,
  input [4:0] prelaunch_R1, prelaunch_R2,
  input [4:0] DECODE_reg_W, EXE_reg_W, MEM_reg_W,
  input DECODE_GPR_write_MEM,   // for detect load->use hazard
  input EXE_has_exception,  // EXE not update GPR when has exception (such as add overflow)

  input IRQ, output ISR_entering, ISR_leaving,   // CP0 ctl

  input clk, rst
);

  wire prelaunch_typeR_ALU, prelaunch_typeR_jr, prelaunch_typeI_ALU, prelaunch_typeI_Branch, prelaunch_typeI_Load, prelaunch_typeI_Store, prelaunch_typeJ, prelaunch_typeCP0_eret;
  assign {prelaunch_typeR_ALU, prelaunch_typeR_jr, prelaunch_typeI_ALU, prelaunch_typeI_Branch, prelaunch_typeI_Load, prelaunch_typeI_Store, prelaunch_typeJ, prelaunch_typeCP0_eret} = ins_prelaunch_flags;


  // hazard detect
  wire data_hazard_R1E = (DECODE_reg_W != 5'b0) & (DECODE_reg_W == prelaunch_R1);
  wire data_hazard_R2E = (DECODE_reg_W != 5'b0) & (DECODE_reg_W == prelaunch_R2);
  wire data_hazard_R1E_ALU  = data_hazard_R1E & ~DECODE_GPR_write_MEM & ~EXE_has_exception;    // execute->use
  wire data_hazard_R2E_ALU  = data_hazard_R2E & ~DECODE_GPR_write_MEM & ~EXE_has_exception;    // execute->use
  wire data_hazard_R1E_load = data_hazard_R1E & DECODE_GPR_write_MEM;     // load->use
  wire data_hazard_R2E_load = data_hazard_R2E & DECODE_GPR_write_MEM;     // load->use
  wire data_hazard_R1M = (EXE_reg_W    != 5'b0) & (EXE_reg_W    == prelaunch_R1);
  wire data_hazard_R2M = (EXE_reg_W    != 5'b0) & (EXE_reg_W    == prelaunch_R2);
  wire data_hazard_R1W = (MEM_reg_W    != 5'b0) & (MEM_reg_W    == prelaunch_R1);
  wire data_hazard_R2W = (MEM_reg_W    != 5'b0) & (MEM_reg_W    == prelaunch_R2);


  // data forward ctl
  assign R1_forward_ctl = data_hazard_R1E_ALU ? 2'b01 :
                          (data_hazard_R1M | data_hazard_R1E_load) ? 2'b10 :
                          data_hazard_R1W ? 2'b11 : 2'b00;

  assign R2_forward_ctl = data_hazard_R2E_ALU ? 2'b01 :
                          (data_hazard_R2M | data_hazard_R2E_load) ? 2'b10 :
                          data_hazard_R2W ? 2'b11 : 2'b00;


  // multi hazard state machine
  localparam NORMAL = 2'h0, LOAD_USE_HAZARD = 2'h1, CONTROL_HAZARD = 2'h2, ISR_ENTER = 2'h3;
  reg [1:0] HAZARD_CONTROL_STATE = NORMAL;
  reg [1:0] HAZARD_CONTROL_STATE_NEXT;

  always @ (posedge clk or posedge rst) begin
    if (rst) HAZARD_CONTROL_STATE <= NORMAL;
    else HAZARD_CONTROL_STATE <= HAZARD_CONTROL_STATE_NEXT;
  end

  wire has_load_hazard = data_hazard_R1E_load | data_hazard_R2E_load; // load->use hazard, this could be auto unlock
  wire has_control_hazard = (prelaunch_typeR_jr | (prelaunch_typeI_Branch & branch_result) | prelaunch_typeJ | prelaunch_typeCP0_eret);
  always @ (*) begin
    case (HAZARD_CONTROL_STATE)
      NORMAL:
        if (has_load_hazard)          HAZARD_CONTROL_STATE_NEXT = LOAD_USE_HAZARD;
        else if (has_control_hazard)  HAZARD_CONTROL_STATE_NEXT = CONTROL_HAZARD;
        else if (IRQ)                 HAZARD_CONTROL_STATE_NEXT = ISR_ENTER;
        else                          HAZARD_CONTROL_STATE_NEXT = NORMAL;

      LOAD_USE_HAZARD:
        if (has_control_hazard)       HAZARD_CONTROL_STATE_NEXT = CONTROL_HAZARD;
        else if (IRQ)                 HAZARD_CONTROL_STATE_NEXT = ISR_ENTER;
        else                          HAZARD_CONTROL_STATE_NEXT = NORMAL;

      CONTROL_HAZARD:
        if (IRQ)                      HAZARD_CONTROL_STATE_NEXT = ISR_ENTER;
        else                          HAZARD_CONTROL_STATE_NEXT = NORMAL;

      ISR_ENTER:                      HAZARD_CONTROL_STATE_NEXT = NORMAL;

    endcase
  end


  assign hazard_lock = (HAZARD_CONTROL_STATE_NEXT != NORMAL);
  assign ISR_entering  = (HAZARD_CONTROL_STATE_NEXT == ISR_ENTER);
  assign ISR_leaving   = (HAZARD_CONTROL_STATE_NEXT == CONTROL_HAZARD) & prelaunch_typeCP0_eret;
  assign PC_use_PC_ctl = (HAZARD_CONTROL_STATE_NEXT == CONTROL_HAZARD) & ~prelaunch_typeCP0_eret;

endmodule
