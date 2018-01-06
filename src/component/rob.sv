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

interface rob_mem_inf;
  bit [`ROB_ENTRY_NUM_WIDTH] head;
  bit                        valid;

  modport rob (output head, valid);
  modport mem (input  head, valid);
endinterface


typedef struct {
  bit valid;
  bit ready;
  bit [`REG_NUM_WIDTH]  rd;
  bit [`COMMON_WIDTH]   val; // / ori_pc
  bit [`COMMON_WIDTH]   next_pc;
  bit [`INST_TAG_WIDTH] tag; // == pos in rob

  bit [`OP_TYPE_WIDTH] op;
} rob_entry;

module rob (
  input clk,
  input rst,

  exwb_rob_tar_res_inf.rob alu_in,
  exwb_rob_tar_res_inf.rob forwarder_in,
  exwb_rob_jump_inf.rob    jump_in,
  exwb_rob_branch_inf.rob  branch_in,
  exwb_rob_tar_res_inf.rob mem_in,

  rob_broadcast_inf.rob broadcast,
  rob_pos_inf.rob       pos,
  wb_id_inf.rob         to_wb,
  rob_mem_inf.rob       to_mem,

  jump_stall_inf.wb     jump_stall
  );

  reg [`ROB_ENTRY_NUM_WIDTH] head, tail;
  rob_entry entries [0:`ROB_ENTRY_NUM-1];

  assign to_mem.head  = head;
  assign to_mem.valid = entries[head].valid;

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

      if (jump_in.target !== `TAG_INVALID) begin
        entries[jump_in.target].ready = 1;
        entries[jump_in.target].val = jump_in.ori_pc;
        entries[jump_in.target].next_pc = jump_in.next_pc;
      end

      if (branch_in.target !== `TAG_INVALID) begin
        entries[branch_in.target].ready = 1;
        entries[branch_in.target].val = $unsigned(branch_in.cmp_res);
        entries[branch_in.target].next_pc = branch_in.next_pc;
      end

      if (mem_in.target !== `TAG_INVALID) begin
        entries[mem_in.target].ready = 1;
        entries[mem_in.target].val = mem_in.result;
      end
    end
  endtask

  task commit_common;
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

  task commit_jump;
    begin
    if (entries[head].valid && entries[head].ready) begin
      to_wb.tag = entries[head].tag;
      to_wb.data = entries[head].val;
      to_wb.rd = entries[head].rd;

      // pc & stall
      jump_stall.reset = 1;
      jump_stall.jump_en = 1;
      jump_stall.jump_addr = entries[head].next_pc;

      entries[head].valid = 0;
      head = head + 1;
    end else begin
      to_wb.tag = `TAG_INVALID;
    end
    end
  endtask

  task commit_branch;
    begin
      if (entries[head].valid && entries[head].ready) begin
        to_wb.tag = `TAG_INVALID;

        jump_stall.reset = 1;
        jump_stall.jump_en = entries[head].val[0];
        jump_stall.jump_addr = entries[head].next_pc;

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
      // commit;
      updata_to_id;
    end
  end

  always @ (negedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      jump_stall.reset = 0;
      jump_stall.jump_en = 0;
      // commit
      case (entries[head].op)
        `OP_NOP, `OP_ADD, `OP_ADDU, `OP_SUB, `OP_SUBU, `OP_AND,
        `OP_AND, `OP_OR,  `OP_NOR,  `OP_XOR, `OP_SLL,  `OP_SRL,
        `OP_SRA, `OP_ROR, `OP_SEQ,  `OP_SLT, `OP_SLTU,
        `OP_STORE, `OP_LOAD:
          commit_common;
        `OP_JAL, `OP_JALR:
          commit_jump;
        `OP_BEQ, `OP_BNE, `OP_BLT, `OP_BGE, `OP_BLTU, `OP_BGEU:
          commit_branch;
        default: ;
      endcase
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


interface exwb_rob_tar_res_inf;
  bit [`COMMON_WIDTH]   result;
  bit [`INST_TAG_WIDTH] target;

  modport rob  (input  result, target);
  modport exwb (output result, target);
endinterface

interface exwb_rob_jump_inf;
  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   ori_pc;
  bit [`COMMON_WIDTH]   next_pc;

  modport rob  (input  target, ori_pc, next_pc);
  modport exwb (output target, ori_pc, next_pc);
endinterface

interface exwb_rob_branch_inf;
  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   next_pc;
  bit                   cmp_res;

  modport rob  (input  target, next_pc, cmp_res);
  modport exwb (output target, next_pc, cmp_res);
endinterface
