`include "common_def.h"

module if_ce (
  input clk,
  input rst,

  input stall,

  output reg ce
  );

  always @ (posedge clk or posedge clk) begin
    if (rst)
      ce <= 0;
    else if (stall == 0)
      ce <= ~ce;
  end

endmodule : if_ce
