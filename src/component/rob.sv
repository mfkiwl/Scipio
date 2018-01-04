`include "common_def.h"

interface rob_broadcast_inf;
  bit ce;
  bit valid [0:`ROB_ENTRY_NUM-1];
  bit ready [0:`ROB_ENTRY_NUM-1];
  bit [`COMMON_WIDTH] val [0:`ROB_ENTRY_NUM-1];
  bit [`INST_TAG_WIDTH] tag [0:`ROB_ENTRY_NUM-1];

  modport snoop (input  valid, ready, val, tag, ce);
  modport rob   (output valid, ready, val, tag, ce);
endinterface

interface rob_pos_inf;
  bit full;
  bit [`INST_TAG_WIDTH] avail_tag;
  bit tag_ce;
  bit tag_token;
  bit [`REG_NUM_WIDTH] rd;
  bit [`OP_TYPE_WIDTH] op;

  modport rob(input  tag_token, tag_ce, rd, op,
              output full, avail_tag);
  modport id (output tag_token, tag_ce, rd, op,
              input  full, avail_tag);
endinterface

interface wb_id_inf;
  bit empty;
  bit [`REG_NUM_WIDTH]  rd;
  bit [`COMMON_WIDTH]   data;
  bit [`INST_TAG_WIDTH] tag;

  modport rob (output rd, data, tag);
  modport id  (input  rd, data, tag);
endinterface

/*
interface rob_inf;
  bit ce;
  bit valid [0:`ROB_ENTRY_NUM-1];
  bit ready [0:`ROB_ENTRY_NUM-1];
  bit [`COMMON_WIDTH] val [0:`ROB_ENTRY_NUM-1];
  bit [`INST_TAG_WIDTH] tag [0:`ROB_ENTRY_NUM-1];

  bit full;
  bit [`INST_TAG_WIDTH] avail_tag;
  bit tag_ce;
  bit tag_token;
  bit [`REG_NUM_WIDTH] rd;
  bit [`OP_TYPE_WIDTH] op;

  // write back
  bit empty;
  bit [`REG_NUM_WIDTH]  wb_reg;
  bit [`COMMON_WIDTH]   wb_data;
  bit [`INST_TAG_WIDTH] wb_tag;
  // TODO: mem, pc

  modport snoop (input valid, ready, val, tag, ce);
  modport broadcast(output valid, ready, val, tag, ce);

  modport rob_id(input  tag_token, tag_ce,
                        rd, op,
                 output full, avail_tag);
  modport id_rob(output tag_token, tag_ce,
                        rd, op,
                 input  full, avail_tag);

  modport to_wb (output wb_reg, wb_data, wb_tag);
  modport wb    (input  wb_reg, wb_data, wb_tag);
endinterface
*/
interface exwb_rob_tar_res_inf;
  bit [`COMMON_WIDTH]   result;
  bit [`INST_TAG_WIDTH] target;

  modport rob  (input  result, target);
  modport exwb (output result, target);
endinterface

typedef struct {
  bit valid;
  bit ready;
  bit [`REG_NUM_WIDTH]  rd;
  bit [`COMMON_WIDTH]   val;
  bit [`INST_TAG_WIDTH] tag; // == pos in rob

  bit [`OP_TYPE_WIDTH] op;
} rob_entry;

module rob (
  input clk,
  input rst,

  // TODO:
  // ex_wb_alu_inf.wb  alu_in,
  exwb_rob_tar_res_inf.rob alu_in,
  exwb_rob_tar_res_inf.rob forwarder_in,

  // rob_inf.rob_id     rob_id,
  // rob_inf.broadcast  broadcast,
  // rob_inf.to_wb      to_wb

  rob_broadcast_inf.rob broadcast,
  rob_pos_inf.rob       pos,
  wb_id_inf.rob         to_wb
  );

  reg [`ROB_ENTRY_NUM_WIDTH] head, tail;
  rob_entry entries [0:`ROB_ENTRY_NUM-1];


  // broadcast
  reg broadcast_ce;
  task broadcast_to_ex;
    integer i;
    begin
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1) begin
        broadcast.valid[i] = entries[i].valid;
        broadcast.ready[i] = entries[i].ready;
        broadcast.val[i] = entries[i].val;
        broadcast.tag[i] = entries[i].tag;
      end
      broadcast_ce = ~broadcast_ce;
      broadcast.ce = broadcast_ce;
    end
  endtask

  task push;
    begin
      if (alu_in.target !== `TAG_INVALID) begin
        entries[alu_in.target].ready = 1;
        entries[alu_in.target].val = alu_in.result;
      end

      if (forwarder_in.target !== `TAG_INVALID) begin
        entries[forwarder_in.target].ready = 1;
        entries[forwarder_in.target].val = forwarder_in.result;
      end
    end
  endtask

  task pop;
    begin
      if (entries[head].valid && entries[head].ready) begin
        to_wb.tag = entries[head].tag;
        to_wb.data = entries[head].val;
        to_wb.rd = entries[head].rd;
        entries[head].valid = 0;
        head = head + 1;
      end else begin
        to_wb.tag = `TAG_INVALID;
      end
    end
  endtask

  task updata_to_id;
    begin
      pos.full = (tail == head - 1);
      pos.avail_tag = tail;
    end
  endtask

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      push;
      broadcast_to_ex;
      // pop;
      updata_to_id;
    end
  end

  always @ (negedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      pop;
      // updata_to_id;
    end
  end

  always @ (pos.tag_ce) begin
    if (pos.tag_token) begin
      entries[tail].valid = 1;
      entries[tail].rd = pos.rd;
      entries[tail].ready = 0;
      entries[tail].op = pos.op;
      entries[tail].tag = tail;

      tail = tail + 1;
    end
  end

  task reset;
    integer i;
    begin
      head <= 0;
      tail <= 0;
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1)
        entries[i].valid <= 0;
      broadcast_ce <= 0;
    end
  endtask

endmodule : rob
