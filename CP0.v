
// CP0 CP0_(reg_out, reg_in, reg_sel, IRQ, ISR_entering, ISR_leaving, ext_int, CP0_we, clk, rst);
module CP0(
  output reg [31:0] reg_out,
  input [31:0] reg_in,
  input [4:0] reg_sel,

  output [31:0] EPC_out, input [31:0] EPC_in,
  
  output IRQ,
  input ISR_entering, ISR_leaving,    // Interrupt Service Routines (interrupt handler) ctl flag
  input [5:0] ext_int,
  input CP0_we, clk, rst
);

  // $12 Status
  reg [31:0] Status;
  wire next_EXL = ISR_entering ? 1'b1 :
                  ISR_leaving  ? 1'b0 : Status[1];

  always @ (posedge clk or posedge rst) begin
    if (rst) Status <= 32'b0;
    else begin
      if (CP0_we & (reg_sel == 32'd12)) Status <= {reg_in[31:2], next_EXL, reg_in[0]};   // EXL should not overwrite by software
      else Status <= {Status[31:2], next_EXL, Status[0]};
    end
  end

  // $13 Cause
  reg [31:0] Cause;
  wire [7:2] Cause_IP = Cause[15:10];
  reg [7:2] Cause_IP_cause_ISR_entering;
  always @ (posedge clk or posedge rst) begin
    if (rst) Cause_IP_cause_ISR_entering <= 6'b0;
    else if (ISR_entering) Cause_IP_cause_ISR_entering <= Cause_IP;
  end

  wire [5:0] ext_int_unset = ~ISR_leaving ? 6'b000000 :
                              Cause_IP_cause_ISR_entering[2] ? 6'b000001 :
                              Cause_IP_cause_ISR_entering[3] ? 6'b000010 :
                              Cause_IP_cause_ISR_entering[4] ? 6'b000100 :
                              Cause_IP_cause_ISR_entering[5] ? 6'b001000 :
                              Cause_IP_cause_ISR_entering[6] ? 6'b010000 :
                              Cause_IP_cause_ISR_entering[7] ? 6'b100000 : 6'b000000;
  always @ (posedge clk or posedge rst) begin
    if (rst) Cause <= 32'b0;
    else Cause[15:10] <= (Cause_IP | ext_int) & ~ext_int_unset;
  end

  // $14 EPC
  wire [31:0] EPC;
  wire [31:0] EPC_reg_in = ISR_entering ? EPC_in : reg_in;   // EPC_in should has higher priority when ISR_entering
  wire EPC_reg_we = ISR_entering | (CP0_we & (reg_sel == 32'd14));
  reg32 r_EPC(EPC, EPC_reg_in, EPC_reg_we, clk, rst);

  // $15 PRId
  wire [31:0] PRId = 32'h_996_faced;


  // reg read
  always @ (*)
    case(reg_sel)
      32'd12: reg_out <= Status;
      32'd13: reg_out <= Cause;
      32'd14: reg_out <= EPC;
      32'd15: reg_out <= PRId;
      default: reg_out <= 32'h_dead_beef;
    endcase
  assign EPC_out = EPC;


  // ext_int
  assign IRQ = Status[0] & ~Status[1] & |(Status[15:10] & Cause[15:10]);  // IE & !EXL & some_int


endmodule

