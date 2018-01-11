`timescale 1ns/1ps

`include "common_def.h"

interface jump_unit_reserv_inf;
  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  bit R;
    // the JAL-type entriy should have a zero-valued val[1]
    // val[2] is imm
  bit [`INST_TAG_WIDTH] tag;       // the tag of val[1]
  bit [`COMMON_WIDTH]   pc_addr;

  modport out (output target, val, tag, pc_addr, R);
  modport in  (input  target, val, tag, pc_addr, R);
endinterface

typedef struct {
  bit valid;
  bit R;

  logic [`INST_TAG_WIDTH] target;

  bit   [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag;
  bit   [`COMMON_WIDTH]   pc_addr;
} jump_unit_reserv_entry;

module jump_unit (
  input rst,
  input clk,

  jump_unit_reserv_inf.in new_entry,
  rob_broadcast_inf.snoop rob_info,

  output reg [`INST_TAG_WIDTH] target,
  output reg [`COMMON_WIDTH]   next_pc,
  output reg [`COMMON_WIDTH]   ori_pc
  );

  jump_unit_reserv_entry entries[0:`RES_ENTRY_NUM-1];

  // reset
  integer ri;
  always @ (posedge rst) begin
    // busy <= 0;
    // full <= 0;
    target <= `TAG_INVALID;
    next_pc <= 0;
    ori_pc  <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end

  task update_val_x;
    input [`RES_ENTRY_NUM_WIDTH] pos;
    integer i, flag;
    begin
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1)
        if (rob_info.valid[i] && rob_info.ready[i]) begin
          if (rob_info.tag[i] == entries[pos].tag) begin
            entries[pos].val[1] = rob_info.val[i];
            entries[pos].tag = `TAG_INVALID;
          end
        end
    end
  endtask

  task insert_inst;
    integer i, pos;
    begin
      if (new_entry.target !== `TAG_INVALID) begin
        pos = -1;
        for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
          pos = (entries[i].valid) ? pos : i;
        entries[pos].valid = 1;
        entries[pos].target = new_entry.target;
        entries[pos].val = new_entry.val;
        entries[pos].tag = new_entry.tag;
        entries[pos].pc_addr = new_entry.pc_addr;
        entries[pos].R = new_entry.R;
      end
    end
  endtask

  task try_issue;
    integer i, pos;
    begin
      pos = -1;
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        if (entries[i].valid && entries[i].tag == `TAG_INVALID)
          pos = i;

      if (pos !== -1) begin
        target = entries[pos].target;
        next_pc = entries[pos].pc_addr + entries[pos].val[1] + entries[pos].val[2];
        if (entries[pos].R) begin
          next_pc = entries[pos].val[1] + entries[pos].val[2];
          next_pc[0] = 0;
        end
        ori_pc  = entries[pos].pc_addr + 4;
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask

  task update_val;
    integer i;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1) begin
        if (entries[i].valid)
          update_val_x(i);
      end
    end
  endtask

  always @ (negedge clk) begin
    if (rst) begin
      ;
    end else begin
      insert_inst;
      update_val;
      try_issue;
    end
  end

endmodule // jump_alu
