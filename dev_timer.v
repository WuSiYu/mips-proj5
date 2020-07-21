// Device: timer
// see 定时器设计规范.docx

// dev dev_(dev_irq, dev_out, dev_in, dev_addr, we, clk, rst);
module dev_timer(
  output dev_irq,
  output [31:0] dev_out,
  input [31:0] dev_in,
  input [7:0] dev_addr,
  input we, clk, rst
);

  reg im; reg [1:0] mode; reg en;
  reg [31:0] preset;
  reg [31:0] count;
  
  
  assign dev_out = (dev_addr == 8'h00) ? {28'b0, im, mode, en} :
                   (dev_addr == 8'h04) ? preset : count;


  always @ (posedge clk or posedge rst) begin
    if (rst) begin {im, mode, en} <= 4'b0; preset <= 32'b0; count <= 32'b0; end
    else if (we & dev_addr == 8'h00) {im, mode, en} <= dev_in[3:0];
    else if (we & dev_addr == 8'h04) begin preset <= dev_in; count <= dev_in; end
    else if (en)
      if (|count) count <= count - 1;
      else if (mode == 2'b01) count <= preset;
  end

  assign dev_irq = en & (mode == 2'b00) & im & (count == 32'b0);

endmodule
