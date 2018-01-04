`include "common_def.h"

interface alu_reserv_inf;
  bit ce;
  bit [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`ALU_TYPE_WIDTH] op;
  modport out(output target, val, tag, op, ce);
  modport in (input  target, val, tag, op, ce);
endinterface

typedef struct {
  bit valid;

  logic [`INST_TAG_WIDTH] target;
  bit [`COMMON_WIDTH]   val [1:2];
  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`ALU_TYPE_WIDTH] op;
} alu_reserv_entry;

module alu (
  input rst,
  input clk,

  output reg full,

  alu_reserv_inf.in        new_entry,
  rob_broadcast_inf.snoop  rob_info,

  output reg[`INST_TAG_WIDTH] target,
  output reg[`COMMON_WIDTH]   result
  );

  reg busy;
  alu_reserv_entry entries[0:`RES_ENTRY_NUM-1];

  // reset
  integer ri;
  always @ (posedge rst) begin
    busy <= 0;
    full <= 0;
    target <= `TAG_INVALID;
    result <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end

  task update_val_x;
    input [`RES_ENTRY_NUM_WIDTH] pos;
    integer i, flag;
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
      end
    end
  endtask

  reg [`ALU_TYPE_WIDTH] calc_type;
  reg [`COMMON_WIDTH]   calc_src [1:2];
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
        calc_type = entries[pos].op;
        calc_src[1] = entries[pos].val[1];
        calc_src[2] = entries[pos].val[2];
        entries[pos].valid = 0;
      end
    end
  endtask

  task check_full;
    integer i;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        full = full & ~entries[i].valid;
    end
  endtask

  // always @ (new_entry.ce or broadcast.ce) begin
  //   insert_inst;
  //   update_val;
  // end

  always @ (negedge clk) begin
    insert_inst;
    update_val;
    try_issue;
    result = alu_calc(calc_type, calc_src[1], calc_src[2]);
  end

  function [`COMMON_WIDTH] alu_calc;
    input [`ALU_TYPE_WIDTH] alu_type;
    input [`COMMON_WIDTH] src1;
    input [`COMMON_WIDTH] src2;
    begin
      case (alu_type)
        `ALU_ADD:	 alu_calc = src1 + src2;
        `ALU_ADDU: alu_calc = src1 + src2;
        `ALU_SUB:	 alu_calc = src1 - src2;
        `ALU_SUBU: alu_calc = src1 - src2;
        `ALU_AND:	 alu_calc = src1 & src2;
        `ALU_OR:	 alu_calc = src1 | src2;
        `ALU_NOR:	 alu_calc = ~(src1 | src2);
        `ALU_XOR:	 alu_calc = src1 ^ src2;
        `ALU_SLL:	 alu_calc = src1 << src2[4:0];
        `ALU_SRL:	 alu_calc = src1 >> src2[4:0];
        // TODO: src1 <=> src2
        `ALU_SRA:	 alu_calc = $signed(src2) >>> src1[4:0];
        `ALU_ROR:	 alu_calc = (src2 >> src1[4:0]) | (src2 << (32-src1[4:0]));
        `ALU_SEQ:	 alu_calc = src1 == src2 ? 32'b1 : 32'b0;
        `ALU_SLT:	 alu_calc = $signed(src1) < $signed(src2) ? 32'b1 : 32'b0;
        `ALU_SLTU: alu_calc = src1 < src2 ? 32'b1 : 32'b0;
        default:;
      endcase
    end
  endfunction

  // calculate
  // TODO: clk
  // always @ (*) begin
  //   busy = 1;
  //   $display("calc: %d, %h, %h", calc_type, calc_src[1], calc_src[2]);
  //   result = alu_calc(calc_type, calc_src[1], calc_src[2]);
  //   $display(" = %d", result);
  //   busy = 0;
  // end

  // calculate

endmodule : alu
