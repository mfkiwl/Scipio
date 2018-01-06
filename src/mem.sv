`include "common_def.h"

interface mem_unit_reserv_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [2:0]             width;
  bit   [`COMMON_WIDTH]   offset;
  bit   [`COMMON_WIDTH]   val[1:2]; // base & src
  logic [`INST_TAG_WIDTH] tag[1:2];
  bit   [`OP_TYPE_WIDTH]  op;

  modport out (output target, width, offset, val, tag, op);
  modport in  (input  target, width, offset, val, tag, op);
endinterface

typedef struct {
  bit valid;

  logic [`INST_TAG_WIDTH] target;
  bit   [2:0]             width;
  bit   [`COMMON_WIDTH]   offset;
  bit   [`COMMON_WIDTH]   val[1:2]; // base & src
  logic [`INST_TAG_WIDTH] tag[1:2];
  bit   [`OP_TYPE_WIDTH]  op;
} mem_reserv_entry;

module mem_unit (
  input clk,
  input rst,

  rob_mem_inf.mem         rob_head_info,
  mem_unit_reserv_inf.in  new_entry,
  rob_broadcast_inf.snoop rob_info,

  output reg [`INST_TAG_WIDTH] target,
  output reg [`COMMON_WIDTH]   result
  );

  reg busy;
  mem_reserv_entry entries[0:`RES_ENTRY_NUM-1];

  task try_issue;
    integer i, pos;
    begin
      if (!busy && rob_head_info.valid) begin
        target = `TAG_INVALID;
        busy = 1;
        pos = -1;
        for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
          if (entries[i].valid && entries[i].tag[1] == `TAG_INVALID
            && entries[i].tag[2] == `TAG_INVALID
            && entries[i].target == rob_head_info.head)
            pos = i;

        if (pos !== -1) begin
          if (entries[pos].op == `OP_STORE)
            store(pos);
          else
            load(pos);
        end else begin
          target = `TAG_INVALID;
        end
        // busy = 0;
      end else begin
        if (entries[pos].op == `OP_STORE)
          restore(pos);
        else
          reload(pos);
      end
    end
  endtask

//////////////rom////////////////
  rom_inf read();
  rom_inf write();
  rom mem_rom(
    .clk(clk),
    .rst(rst),

    .read(read),
    .write(write)
    );
//////////////store//////////////
  task store;
    input integer pos;
    begin
      write.en = 1;
      write.addr = entries[pos].val[1] + entries[pos].offset;
      write.byte_num = entries[pos].width;
      write.data = entries[pos].val[2];
    end
  endtask
  task restore;
    input integer pos;
    begin
      if (write.done) begin
        write.en = 0;
        target = entries[pos].target;
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask
//////////////load//////////////
  task load;
    input integer pos;
    begin
      read.en = 1;
      read.byte_num = entries[pos].width;
      read.addr = entries[pos].val[1] + entries[pos].offset;
    end
  endtask
  task reload;
    input integer pos;
    begin
      if (read.done) begin
        read.en = 0;
        target = entries[pos].target;
        if (entries[pos].op == `OP_LOAD)
          result = read.data; // TODO: extension
        else
          result = read.data;
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask
////////////////////////////////

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
        entries[pos].width = new_entry.width;
        entries[pos].offset = new_entry.offset;
        entries[pos].val = new_entry.val;
        entries[pos].tag = new_entry.tag;
        entries[pos].op = new_entry.op;
      end
    end
  endtask

  // reset
  integer ri;
  always @ (posedge rst) begin
    busy <= 0;
    // full <= 0;
    target <= `TAG_INVALID;
    result <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end

endmodule // mem
