
// dm_warpper dm_warpper_(dm_addr, dm_din, dm_dout, D, A, D_in, data_len, load_sign);
module dm_warpper(
  output [13:0] dm_addr,  // dm interface
  output reg [31:0] dm_din,
  input [31:0] dm_dout,

  output reg [31:0] D,
  input [31:0] A, D_in,
  input [1:0] data_len,   // 00 - byte, 01 - half, 11 - word
  input load_sign
);

  wire [1:0] addr_low2 = A[1:0];
  assign dm_addr = {A[13:2], 2'b0};


  // - PRE MEM

  // replace mux
  reg [31:0] data_8_to_32;
  reg [31:0] data_16_to_32;
  always @ (*) begin
    case (addr_low2)
      2'h0: data_8_to_32 = {dm_dout[31:8], D_in[7:0]};
      2'h1: data_8_to_32 = {dm_dout[31:16], D_in[7:0], dm_dout[7:0]};
      2'h2: data_8_to_32 = {dm_dout[31:24], D_in[7:0], dm_dout[15:0]};
      2'h3: data_8_to_32 = {D_in[7:0], dm_dout[23:0]};
    endcase
    case (addr_low2)
      2'h0: data_16_to_32 = {dm_dout[31:16], D_in[15:0]};
      2'h2: data_16_to_32 = {D_in[15:0], dm_dout[15:0]};
      default: data_16_to_32 = 16'h_dead;
    endcase   
  end

  // mode mux
  always @ (*) begin
    case (data_len)
      2'b00: dm_din = data_8_to_32;
      2'b01: dm_din = data_16_to_32;
      2'b11: dm_din = D_in;
      default: dm_din = 32'h_dead_beef;
    endcase
  end



  // - POST MEM
  
  // address mux
  reg [7:0] dat8;
  reg [15:0] dat16;

  always @ (*) begin
    case (addr_low2)
      2'h0: dat8 = dm_dout[7:0];
      2'h1: dat8 = dm_dout[15:8];
      2'h2: dat8 = dm_dout[23:16];
      2'h3: dat8 = dm_dout[31:24];
    endcase
    case (addr_low2)
      2'h0: dat16 = dm_dout[15:0];
      2'h2: dat16 = dm_dout[31:16];
      default: dat16 = 16'h_dead;
    endcase
  end

  // ext
  wire [31:0]dat8_ext;
  assign dat8_ext = { {24{dat8[7] & load_sign}}, dat8};
  wire [31:0]dat16_ext;
  assign dat16_ext = { {24{dat16[15] & load_sign}}, dat16};

  // mode mux
  always @ (*) begin
    case (data_len)
      2'b00: D = dat8_ext;
      2'b01: D = dat16_ext;
      2'b11: D = dm_dout;
      default: D = 32'h_dead_beef;
    endcase
  end

endmodule
