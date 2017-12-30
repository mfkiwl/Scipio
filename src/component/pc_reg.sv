`include "common_def.h"

module pc_reg (
  input clk,
  input rst,
  // input stall,

  input [`COMMON_WIDTH] next_pc,

  output reg [`COMMON_WIDTH] pc_addr
  );

  reg [`COMMON_WIDTH] pc;
  always @ ( * ) pc = next_pc;

  always @ (posedge clk or posedge rst) begin
    // if (stall) begin
    //   pc_addr <= pc - 4;
    // end else begin
      if (rst) begin
        pc_addr <= -4;
        pc <= 0;
      end else begin
        pc_addr <= pc;
      // end
    end
  end

endmodule : pc_reg
