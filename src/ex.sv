`timescale 1ns/1ps

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
  bit [2:0]           width;

  modport ex  (input  unit, target, val, tag, op, ce, pc_addr, offset, width);
  modport idex(output unit, target, val, tag, op, ce, pc_addr, offset, width);
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

interface ex_exwb_mem_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [`COMMON_WIDTH] result;

  modport exwb (input  target, result);
  modport ex   (output target, result);
endinterface

interface mem_dcache_inf;
  bit [2:0]  rw_flag;
  bit [31:0] addr;
  bit [31:0] read_data;
  bit [31:0] write_data;
  bit [3:0]  write_mask;
  bit        busy;
  bit        done;

  modport mem (output rw_flag, addr, write_data, write_mask,
               input  read_data, busy, done);
endinterface

module ex (
  input rst,
  input clk,

  // input
  idex_ex_inf.ex          in,
  rob_broadcast_inf.snoop rob_info,
  rob_mem_inf.mem         rob_head_info,

  // to
  ex_exwb_alu_inf.ex       alu_out,
  ex_exwb_forwarder_inf.ex forwarder_out,
  ex_exwb_jump_inf.ex      jump_out,
  ex_exwb_branch_inf.ex    branch_out,
  ex_exwb_mem_inf.ex       mem_out,

  mem_dcache_inf          with_dcache,

  output full [0:`EX_UNIT_NUM-1]
  );


  alu_reserv_inf alu_inf();
    assign alu_inf.target = (in.unit == `EX_ALU_UNIT) ? in.target : `TAG_INVALID;
    assign alu_inf.val[1] = in.val[1];
    assign alu_inf.val[2] = in.val[2];
    assign alu_inf.tag[1] = in.tag[1];
    assign alu_inf.tag[2] = in.tag[2];
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
    assign jump_unit_inf.val[1] = in.val[1];
    assign jump_unit_inf.val[2] = in.val[2];
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
    assign branch_unit_inf.val[1] = in.val[1];
    assign branch_unit_inf.val[2] = in.val[2];
    assign branch_unit_inf.tag[1] = in.tag[1];
    assign branch_unit_inf.tag[2] = in.tag[2];
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

  mem_unit_reserv_inf mem_unit_inf();
    assign mem_unit_inf.target = (in.unit == `EX_MEM_UNIT) ? in.target : `TAG_INVALID;
    assign mem_unit_inf.val[1] = in.val[1];
    assign mem_unit_inf.val[2] = in.val[2];
    assign mem_unit_inf.tag[1] = in.tag[1];
    assign mem_unit_inf.tag[2] = in.tag[2];
    assign mem_unit_inf.width = in.width;
    assign mem_unit_inf.offset = in.offset;
    assign mem_unit_inf.op  = in.op;
  // rob_mem_inf mem_unit_rob_head_info();
  //   assign mem_unit_rob_head_info.head = rob_head_info.head;
  //   assign mem_unit_rob_head_info.valid = rob_head_info.valid;
  // mem_dcache md();
  //   assign with_dcache.rw_flag = md.rw_flag;
  //   assign with_dcache.addr    = md.addr;
  //   assign with_dcache.write_data = md.write_data;
  //   assign with_dcache.write_mask = md.write_mask;
  //   assign md.read_data = with_dcache.read_data;
  //   assign md.busy = with_dcache.busy;
  //   assign md.done = with_dcache.done;
  mem_unit ex_mem(
    .clk(clk),
    .rst(rst),
    .new_entry(mem_unit_inf),
    .rob_info(rob_info),
    .rob_head_info(rob_head_info),
    .with_dcache(with_dcache),

    .target(mem_out.target),
    .result(mem_out.result)
    );

endmodule : ex
