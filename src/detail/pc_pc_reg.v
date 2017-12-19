`include "define.h"

module pc_pc_reg (
  input clk,
  input rst,

  output reg [`COMMON_WIDTH] addr
  );

  reg [`PC_MAX_WIDTH] pc;

  always @ (posedge clk) begin
    if (rst) begin
      addr <= 0;
      pc   <= 0;
    end
    else begin
      addr <= pc;
      pc   <= pc + 4;
    end
  end

endmodule // pc_pc_reg
