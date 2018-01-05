`include "common_def.h"

interface idex_ex_inf;
  bit ce;

  bit [`EX_UNIT_NUM_WIDTH] unit;

  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`OP_TYPE_WIDTH]  op;

  bit [`COMMON_WIDTH] pc_addr;

  modport ex  (input  unit, target, val, tag, op, ce, pc_addr);
  modport idex(output unit, target, val, tag, op, ce, pc_addr);
endinterface

interface ex_exwb_alu_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [`COMMON_WIDTH] result;

  modport exwb (input  target, result);
  modport ex   (output target, result);
endinterface

interface ex_exwb_forwarder_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [`COMMON_WIDTH] result;

  modport exwb (input  target, result);
  modport ex   (output target, result);
endinterface

interface ex_exwb_jump_inf;
logic [`INST_TAG_WIDTH] target;
bit   [`COMMON_WIDTH]   ori_pc;
bit   [`COMMON_WIDTH]   next_pc;

modport exwb (input  target, ori_pc, next_pc);
modport ex   (output target, ori_pc, next_pc);
endinterface

module ex (
  input rst,
  input clk,

  // input
  idex_ex_inf.ex          in,
  rob_broadcast_inf.snoop rob_info,

  // to
  ex_exwb_alu_inf.ex       alu_out,
  ex_exwb_forwarder_inf.ex forwarder_out,
  ex_exwb_jump_inf.ex      jump_out,

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

  forwarder_reserv_inf forwarder_inf();
    assign forwarder_inf.target = (in.unit == `EX_FORWARDER_UNIT) ? in.target : `TAG_INVALID;
    assign forwarder_inf.val = in.val[2];
    assign forwarder_inf.tag = in.tag[2];
  forwarder ex_forwarder(
    .rst(rst),
    .clk(clk),

    .new_entry(forwarder_inf),
    .rob_info(rob_info),

    .target(forwarder_out.target),
    .result(forwarder_out.result)
    );

  jump_unit_reserv_inf jump_unit_inf();
    assign jump_unit_inf.target = (in.unit == `EX_JUMP_UNIT) ? in.target : `TAG_INVALID;
    assign jump_unit_inf.val = in.val;
    assign jump_unit_inf.tag = in.tag[2];
    assign jump_unit_inf.pc_addr = in.pc_addr;
  jump_unit ex_jump_unit(
    .rst(rst),
    .clk(clk),
    .new_entry(jump_unit_inf),
    .rob_info(rob_info),

    .target(jump_out.target),
    .next_pc(jump_out.next_pc),
    .ori_pc(jump_out.ori_pc)
    );

endmodule : ex
