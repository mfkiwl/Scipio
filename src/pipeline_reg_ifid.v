`include "define.h"

module pipeline_reg_ifid (
  input clk,
  input rst,

  input [`COMMON_WIDTH] inst_in,

  output reg [`COMMON_WIDTH] inst_out
  );

  task reset;
    begin
      inst_out <= 0;
    end
  endtask

  always @ (posedge clk) begin
    if (rst)
      reset;
    else begin
      inst_out <= inst_in;
    end
  end

endmodule // pipeline_reg_ifid
