`timescale 1ns/1ps

`include "common_def.h"

module idex (
  input clk,
  input rst,

  id_idex_inf.idex from_id,
  idex_ex_inf.idex to_ex

  // full_stall_inf.idex full_stall
  );

  always @ (posedge clk or posedge rst) begin
      if (rst) begin
        ; // TODO: reset
      end else begin
        // to_ex.target <= (full_stall) ? `TAG_INVALID : from_id.target;
        to_ex.target <= from_id.target;
        to_ex.unit <= from_id.ex_unit;
        to_ex.val <= from_id.val;
        to_ex.tag <= from_id.tag;
        to_ex.op <= from_id.op;
        to_ex.pc_addr <= from_id.pc_addr;
        to_ex.offset <= from_id.offset;
        to_ex.width  <= from_id.width;
        // to_ex.R      <= from_id.R;

        to_ex.ce <= ~to_ex.ce; // I forgot why I wrote this line
      end
  end

endmodule : idex
