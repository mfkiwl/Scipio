`include "common_def.h"

module ifid (
  input clk,
  input rst,

  jump_stall_inf.ifid jump_stall,
  full_stall_inf.ifid full_stall,

  pif_ifid_inf.ifid  from_if,

  ifid_id_inf.ifid to_id
  );

  reg stall_prev;
  reg stall = jump_stall.stall || full_stall.stall;

  always @ (posedge clk or posedge rst) begin
    if (rst || jump_stall.stall || stall_prev) begin
      to_id.inst    <= 0;
      to_id.pc_addr <= 0;
      stall_prev <= 0;
    end else if (full_stall.stall) begin
      stall_prev <= 0;
    end else begin
      to_id.inst <= from_if.inst;
      to_id.pc_addr <= from_if.pc_addr;
    end
  end

  always @ (negedge stall) begin
    stall_prev = 1;
  end

endmodule // ifid
