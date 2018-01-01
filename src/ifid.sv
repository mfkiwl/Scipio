`include "common_def.h"

module ifid (
  input clk,
  input rst,

  input stall,

  pif_ifid_inf.ifid  from_if,

  ifid_id_inf.ifid to_id
  );

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      to_id.inst    <= 0;
      to_id.pc_addr <= 0;
    end else if (!stall) begin
      to_id.inst <= from_if.inst;
      to_id.pc_addr <= from_if.pc_addr;
    end
  end

endmodule // ifid
