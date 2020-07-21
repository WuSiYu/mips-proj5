
// immExt immext(out, in, extSign);
module immExt(
  output [31:0] out,
  input [15:0] in, input extSign
);

  wire [31:0] out_extZero = {16'b0, in};
  wire [31:0] out_extSign = {{16{in[15]}}, in};
  assign out = extSign ? out_extSign : out_extZero;

endmodule
