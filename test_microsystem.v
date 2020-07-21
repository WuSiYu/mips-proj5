
module test_microsystem;
  reg clk, rst;
  microsystem microsystem_(clk, rst);
  

  integer i;
  initial begin
    for (i = 0; i < 12*1024; i = i + 1) microsystem_.soc.DM.dm[i] = 32'b0;
    for (i = 0; i <  8*1024; i = i + 1) microsystem_.soc.IM.im[i] = 32'b0;
    //$readmemh("code-eq.txt", microsystem_.soc.IM.im);
    $readmemh("code-prime.txt", microsystem_.soc.IM.im);
    //$readmemh("timer.txt", microsystem_.soc.IM.im);
    $readmemh("timer_ISR.txt", microsystem_.soc.IM.im, 16'h_1180);
    clk = 1; rst = 0;
    #5 rst = 1;
    #5 rst = 0;
    #233300 $display("test_microsystem.v: dev_debug_input_.val changed!");
    microsystem_.dev_debug_input_.val = 32'h_12345678;
    #66600 $display("test_microsystem.v: dev_debug_input_.val changed!");
    microsystem_.dev_debug_input_.val = 32'h_87654321;
  end
  
  always #50 clk = ~clk;

endmodule



