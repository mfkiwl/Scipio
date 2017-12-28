`include "common_def.h"

interface ifid_inf;
  bit [`COMMON_WIDTH] inst;
  bit [`COMMON_WIDTH] pc_addr;

  modport out(output inst, pc_addr);
  modport in (input  inst, pc_addr);
endinterface

module ifid (
  input clk,
  input rst,

  ifid_inf.in  from_if,
  ifid_inf.out to_id
  );

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      to_id.inst    <= 0;
      to_id.pc_addr <= 0;
    end else begin
      $display("ifid: %h", from_if.inst);
      to_id.inst <= from_if.inst;
      to_id.pc_addr <= from_if.pc_addr;
    end
  end

endmodule // ifid
