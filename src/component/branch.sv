`include "common_def.h"

interface branch_unit_reserv_inf;
  logic [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`COMMON_WIDTH]   pc_addr;
  bit [`COMMON_WIDTH]   offset;
  bit [`OP_TYPE_WIDTH]  op;

  modport out (output target, val, tag, pc_addr, offset, op);
  modport in  (input  target, val, tag, pc_addr, offset, op);
endinterface

typedef struct {
  bit valid;

  logic [`INST_TAG_WIDTH] target;

  bit   [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit   [`COMMON_WIDTH]   pc_addr;
  bit   [`COMMON_WIDTH]   offset;
  bit   [`OP_TYPE_WIDTH]  op;
} branch_unit_reserv_entry;

module branch_unit (
  input rst,
  input clk,

  branch_unit_reserv_inf.in new_entry,
  rob_broadcast_inf.snoop   rob_info,

  output reg [`INST_TAG_WIDTH] target,
  output reg                   cmp_res,
  output reg [`COMMON_WIDTH]   next_pc
  );

  branch_unit_reserv_entry entries[0:`RES_ENTRY_NUM-1];

  // reset
  integer ri;
  always @ (posedge rst) begin
    // busy <= 0;
    // full <= 0;
    target <= `TAG_INVALID;
    next_pc <= 0;
    cmp_res <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end

  always @ (negedge clk) begin
    if (rst) begin
      ;
    end else begin
      insert_inst;
      update_val;
      try_issue;
    end
  end

  task update_val_x;
    input [`RES_ENTRY_NUM_WIDTH] pos;
    integer i;
    begin
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1)
        if (rob_info.valid[i] && rob_info.ready[i]) begin
          if (rob_info.tag[i] == entries[pos].tag[1]) begin
            entries[pos].val[1] = rob_info.val[i];
            entries[pos].tag[1] = `TAG_INVALID;
          end
          if (rob_info.tag[i] == entries[pos].tag[2]) begin
            entries[pos].val[2] = rob_info.val[i];
            entries[pos].tag[2] = `TAG_INVALID;
          end
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
        entries[pos].op = new_entry.op;
        entries[pos].pc_addr = new_entry.pc_addr;
        entries[pos].offset = new_entry.offset;
      end
    end
  endtask

  task try_issue;
    integer i, pos;
    begin
      pos = -1;
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1) begin
        if (entries[i].valid && entries[i].tag[1] == `TAG_INVALID
          && entries[i].tag[2] == `TAG_INVALID)
          pos = i;
      end
      if (pos !== -1) begin
        target = entries[pos].target;
        next_pc = entries[pos].pc_addr + entries[pos].offset;
        cmp_res = compare(entries[pos].val, entries[pos].op);
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask

  function compare;
    input bit [`COMMON_WIDTH]  val[1:2];
    input bit [`OP_TYPE_WIDTH] op;
    begin
      case (op)
        `OP_BEQ:  compare = (val[1] == val[2]);
        `OP_BNE:  compare = (val[1] !== val[2]);
        `OP_BLT:  compare = (val[1] < val[2]);
        `OP_BGE:  compare = (val[1] > val[2]);
        `OP_BLTU: compare = ($unsigned(val[1]) < $unsigned(val[2]));
        `OP_BGEU: compare = ($unsigned(val[1]) > $unsigned(val[2]));
        default: compare = 0;
      endcase
    end
  endfunction

endmodule : branch_unit
