`include "common_def.h"

interface ex_in_inf;
  bit ce;

  bit [`EX_UNIT_NUM_WIDTH] unit;

  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`OP_TYPE_WIDTH]  op;

  modport in (input  unit, target, val, tag, op, ce);
  modport out(output unit, target, val, tag, op, ce);
endinterface

// just alu
interface ex_alu_out_inf;
  logic [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH] result;

  modport in (input  target, result);
  modport out(output target, result);
endinterface

module ex (
  input rst,
  input clk,

  ex_in_inf.in       in,
  rob_inf.snoop      rob_info,
  ex_alu_out_inf.out alu_out,

  output full [0:`EX_UNIT_NUM-1]
  );


  alu_reserv_inf alu_inf();
    assign alu_inf.target = (in.unit == `EX_ALU_UNIT) ? in.target : `TAG_INVALID;
    assign alu_inf.val = in.val;
    assign alu_inf.tag = in.tag;
    assign alu_inf.op  = in.op;
    assign alu_inf.ce  = in.ce;

  alu ex_alu(
    .rst(rst),
    .clk(clk),
    .full(full[`EX_ALU_UNIT]),
    .new_entry(alu_inf),
    .rob_info(rob_info),
    .target(alu_out.target),
    .result(alu_out.result)
    );

endmodule : ex
