`include "common_def.h"

interface idex_inf;
  bit [`EX_UNIT_NUM_WIDTH] ex_unit;

  // reservation station entry
  bit [`INST_OP_WIDTH]  op;
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`COMMON_WIDTH]   val [1:2];
  // bit [`RES_ADDR_WIDTH] addr;
  bit [`INST_TAG_WIDTH] target; // the position in ROB

  modport in (input  ex_unit, op, tag, val, target);
  modport out(output ex_unit, op, tag, val, target);
endinterface

module idex (
  input clk,
  input rst,

  idex_inf.in  from_id,
  idex_inf.out to_ex
  );

endmodule : idex
