`include "common_def.h"

module pc_reg (
  input clk,
  input rst,
  input stall,

  input [`COMMON_WIDTH] next_pc,

  output reg [`COMMON_WIDTH] pc_addr
  );

  reg [`COMMON_WIDTH] pc;

  always @ (posedge clk or posedge rst) begin
    if (stall == 0) begin
      if (rst) begin
        inst <= 0;
        pc_addr <= 0;
        pc <= 0;
      end else begin
        pc_addr <= pc;
        pc <= next_pc;
      end
    end
  end

endmodule : pc_reg
