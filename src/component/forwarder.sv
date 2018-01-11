`timescale 1ns/1ps

`include "common_def.h"

interface forwarder_reserv_inf;
  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val;
  bit [`INST_TAG_WIDTH] tag;

  modport idex (output target, val, tag);
  modport ex   (input  target, val, tag);
endinterface

typedef struct {
  bit valid;

  logic [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val;
  bit [`INST_TAG_WIDTH] tag;
} forwarder_reserv_entry;

module forwarder (
  input clk,
  input rst,

  forwarder_reserv_inf.ex  new_entry,
  rob_broadcast_inf.snoop  rob_info,

  output reg[`INST_TAG_WIDTH] target,
  output reg[`COMMON_WIDTH]   result
  );

  forwarder_reserv_entry entries[0:`RES_ENTRY_NUM-1];

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

  task try_issue;
    integer i, pos;
    begin
      pos = -1;
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        if (entries[i].valid && entries[i].tag == `TAG_INVALID)
          pos = i;

      if (pos !== -1) begin
        target = entries[pos].target;
        result = entries[pos].val;
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask

  always @ (negedge clk) begin
    if (!rst) begin
      insert_inst;
      update_val;
      try_issue;
    end
  end

  integer ri;
  always @ (posedge rst) begin
    target <= `TAG_INVALID;
    result <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end

  task update_val_x;
    input [`RES_ENTRY_NUM_WIDTH] pos;
    integer i;
    begin
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1)
        if (rob_info.valid[i] && rob_info.ready[i]) begin
          if (rob_info.tag[i] == entries[pos].tag) begin
            entries[pos].val = rob_info.val[i];
            entries[pos].tag = `TAG_INVALID;
          end
        end
    end
  endtask

endmodule : forwarder
