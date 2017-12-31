`include "common_def.h"

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

  ex_alu_out_inf.in  alu_in,

  rob_inf.rob_id     rob_id,
  rob_inf.broadcast  broadcast,
  rob_inf.to_wb      to_wb
  );

  reg [`ROB_ENTRY_NUM_WIDTH] head, tail;
  rob_entry entries [0:`ROB_ENTRY_NUM-1];

  // broadcast
  genvar gi;
  generate
    for (gi = 0; gi < `ROB_ENTRY_NUM; gi = gi + 1)
    begin : bc
      assign broadcast.valid[gi] = entries[gi].valid;
      assign broadcast.ready[gi] = entries[gi].ready;
      assign broadcast.val[gi] = entries[gi].val;
      assign broadcast.tag[gi] = entries[gi].tag;
    end
  endgenerate

  task push;
    begin
      if (alu_in.target == `TAG_INVALID)
        return;
      entries[alu_in.target].ready = 1;
      entries[alu_in.target].val = alu_in.result;
    end
  endtask

  task pop;
    begin
      if (entries[head].valid && entries[head].ready) begin
        to_wb.wb_tag = entries[head].tag;
        to_wb.wb_data = entries[head].val;
        to_wb.wb_reg = entries[head].rd;
        entries[head].valid = 0;
        head = head + 1;
      end else begin
        to_wb.wb_tag = `TAG_INVALID;
      end
    end
  endtask

  task updata_to_id;
    begin
      rob_id.full = (tail == head - 1);
      rob_id.avail_tag = tail;
    end
  endtask

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      push;
      pop;
      updata_to_id;
    end
  end

  always @ (rob_id.tag_ce) begin
    if (rob_id.tag_token) begin
      entries[tail].valid = 1;
      entries[tail].rd = rob_id.rd;
      entries[tail].ready = 0;
      entries[tail].op = rob_id.op;
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
    end
  endtask

endmodule : rob
