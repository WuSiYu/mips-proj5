// Device: clk_counter
// {[addr 0x01], [addr 0x00]} contains clock tick count

// dev dev_(dev_out, dev_in, dev_addr, we, clk, rst);
module dev_clk_counter(
  output [31:0] dev_out,
  input [31:0] dev_in,
  input [7:0] dev_addr,
  input we, clk, rst
);
  
  reg [31:0] counter0;
  reg [31:0] counter1;
  always @ (posedge clk or posedge rst)
    if (rst) begin
      counter0 <= 32'b0;
      counter1 <= 32'b0;
    end else begin
      counter0 <= counter0 + 1;
      counter1 <= (counter0 == 32'h_ffff_ffff) ? counter1 + 1 : counter1;
    end

  assign dev_out = 
    dev_addr == 8'h00 ? counter0 :
    dev_addr == 8'h04 ? counter1 : 32'h_dead_beef;

endmodule

