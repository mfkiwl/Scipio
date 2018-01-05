`include "common_def.h"

module idex (
  input clk,
  input rst,

  id_idex_inf.idex from_id,
  idex_ex_inf.idex to_ex
  );

  always @ (posedge clk or posedge rst) begin
      if (rst) begin
        ; // TODO: reset
      end else begin
        to_ex.unit <= from_id.ex_unit;
        to_ex.val <= from_id.val;
        to_ex.tag <= from_id.tag;
        to_ex.op <= from_id.op;
        to_ex.target <= from_id.target;
        to_ex.pc_addr <= from_id.pc_addr;

        to_ex.ce <= ~to_ex.ce; // I forgot why I wrote this line
      end
  end

endmodule : idex
