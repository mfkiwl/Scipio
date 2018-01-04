`include "common_def.h"

interface ifid_id_inf;
  bit [`COMMON_WIDTH] pc_addr;
  bit [`COMMON_WIDTH] inst;

  modport id   (input  pc_addr, inst);
  modport ifid (output pc_addr, inst);
endinterface

interface id_idex_inf;
  bit [`EX_UNIT_NUM_WIDTH] ex_unit;
  bit [`OP_TYPE_WIDTH]     op;

  logic [`INST_TAG_WIDTH] tag [1:2];
  bit [`COMMON_WIDTH]     val [1:2];

  bit [`INST_TAG_WIDTH] target; // the position in ROB

  modport id  (output ex_unit, op, tag, val, target);
  modport idex (input ex_unit, op, tag, val, target);
endinterface

module id (
  input clk,
  input rst,
  input rst_tag,

  ifid_id_inf.id from_ifid,
  rob_pos_inf.id rob_pos,
  wb_id_inf.id   wb,

  input reservation_full [0:`EX_UNIT_NUM-1],
  output reg stall_if,

  id_idex_inf.id to_idex
  );

  // stall
  // always @ ( * ) begin
  //   if (rob_full || (reservation_full[to_idex.ex_unit])) begin
  //     stall_if <= 1;
  //     to_idex.target <= 0;
  //   end else begin
  //     stall_if <= 0;
  //     to_idex.target <= target;
  //   end
  // end

  //////////////////////
  decoder_control_inf  decoder_control();
  decoder_reg_file_inf decoder_reg_file();
  reg_file_result_inf  reg_file_result();

  decoder id_decoder(
    .rst(rst),
    .inst(from_ifid.inst),
    .pc_addr(from_ifid.pc_addr),

    .control(decoder_control),
    .decoder_reg_file(decoder_reg_file)
    );

  wire [`INST_TAG_WIDTH] target = rob_pos.avail_tag;
  assign to_idex.target = target;
  reg_file id_reg_file(
    .clk(clk),
    .rst(rst),
    .rst_tag(rst_tag),

    .rd_tag(target),
    .wb(wb),
    .in(decoder_reg_file),
    .out(reg_file_result)
    );

  /// control & forward
  // forward
  assign to_idex.op      = decoder_control.op;
  assign to_idex.ex_unit = decoder_control.ex_unit;

  // MUX (tag, val)
  always @ ( * ) begin
    // src1
    to_idex.val[1] <= reg_file_result.val[1];
    to_idex.tag[1] <= (decoder_control.rs_en[1]) ?
                      reg_file_result.tag[1] : `TAG_INVALID;
    // src2
    if (decoder_control.imm_en) begin
      to_idex.val[2] <= decoder_control.imm;
      to_idex.tag[2] <= `TAG_INVALID;
    end else begin
      to_idex.val[2] <= reg_file_result.val[2];
      to_idex.tag[2] <= (decoder_control.rs_en[2]) ?
                        reg_file_result.tag[2] : `TAG_INVALID;
    end
  end

  // tag (rob)
  reg tag_ce;
  always @ (posedge rst or posedge clk) begin
    if (rst) begin
      tag_ce = 0;
      rob_pos.tag_token = 0;
    end
  end
  always @ (negedge clk) begin
    // TODO: no inst, ROB FULL
    tag_ce = ~tag_ce;
    rob_pos.tag_ce = tag_ce;
    if (rob_pos.full || decoder_control.ex_unit == `EX_ERR_UNIT) begin
      rob_pos.tag_token = 0;
    end else begin
      // target = rob_pos.avail_tag;
      rob_pos.tag_token = 1;
      rob_pos.rd = decoder_reg_file.rd;
      rob_pos.op = decoder_control.op;
    end
  end

endmodule // id

interface decoder_reg_file_inf;
  bit [`REG_NUM_WIDTH] rs[1:2];
  bit                  rd_en;
  bit [`REG_NUM_WIDTH] rd;

  // rd_en = 1 if and only if reg[rd] will be written
  // Otherwise, rd_en = 0;
  // Tag of reg[0] always is TAG_INVALID

  // rs_en[i] is not provided because src[i] will be
  // read no matter whether it is needed, and a MUX
  // will determine whether it should be forwarded.
  modport decoder (output rs, rd_en, rd);
  modport reg_file(input  rs, rd_en, rd);
endinterface

interface decoder_control_inf;
  bit [`OP_TYPE_WIDTH]     op;
  bit [`EX_UNIT_NUM_WIDTH] ex_unit;

  bit                 rs_en[1:2];
  bit [`COMMON_WIDTH] imm;
  bit                 imm_en;
  // TODO: pc related tags

  // imm is the sign extended immediate value
  // imm_en = 1   iff imm is required
  // rs_en[i] = 1 iff rs[i] is required
  modport decoder (output op, ex_unit, rs_en, imm, imm_en);
endinterface

interface reg_file_result_inf;
  bit [`COMMON_WIDTH]   val[1:2];
  bit [`INST_TAG_WIDTH] tag[1:2];

  // tag is used to determine whether the value is valid
  modport reg_file (output val, tag);
endinterface
