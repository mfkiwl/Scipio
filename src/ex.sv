`include "common_def.h"

interface idex_ex_inf;
  bit ce;

  bit [`EX_UNIT_NUM_WIDTH] unit;

  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`OP_TYPE_WIDTH]  op;

  bit [`COMMON_WIDTH] pc_addr;

  bit [`COMMON_WIDTH] offset;

  modport ex  (input  unit, target, val, tag, op, ce, pc_addr, offset);
  modport idex(output unit, target, val, tag, op, ce, pc_addr, offset);
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

interface ex_exwb_branch_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [`COMMON_WIDTH]   next_pc;
  bit                     cmp_res;

  modport exwb (input  target, next_pc, cmp_res);
  modport ex   (output target, next_pc, cmp_res);
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
  ex_exwb_branch_inf.ex    branch_out,

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

  branch_unit_reserv_inf branch_unit_inf();
    assign branch_unit_inf.target = (in.unit == `EX_BRANCH_UNIT) ? in.target : `TAG_INVALID;
    assign branch_unit_inf.val = in.val;
    assign branch_unit_inf.tag = in.tag;
    assign branch_unit_inf.pc_addr = in.pc_addr;
    assign branch_unit_inf.offset  = in.offset;
    assign branch_unit_inf.op = in.op;
  branch_unit ex_branch_unit(
    .rst(rst),
    .clk(clk),
    .new_entry(branch_unit_inf),
    .rob_info(rob_info),

    .target(branch_out.target),
    .cmp_res(branch_out.cmp_res),
    .next_pc(branch_out.next_pc)
    );

endmodule : ex
