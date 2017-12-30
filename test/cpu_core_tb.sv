`include "common_def.h"

module cpu_core_tb;
  reg clk;
  reg rst;
  reg stall;

  cpu_core cpu(
    .clk(clk),
    .rst(rst)
    );

  initial begin
    stall = 0;
    clk = 0;
    rst = 1;
    #200;
    rst = 0;
    forever #200 clk = ~clk;
  end

endmodule
