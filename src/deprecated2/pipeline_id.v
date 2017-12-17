`include "define.h"

module pipeline_id (
  input rst,
  input clk, // only used to reset stage_reg

  // from if/id
  input [`COMMON_WIDTH] inst,

  // from forwarding
  input [`REG_NUM]         reg_forward_ex,
  input [`REG_NUM]         reg_forward_mem,
  input [`COMMON_WIDTH]    data_forward_ex,
  input [`COMMON_WIDTH]    data_forward_mem,

  // decoder to id/ex
  output                   write_alu_result_tag,
  output [`ALU_TYPE_WIDTH] alu_type,
  output [2:0]             src_tag,
  output [`COMMON_WIDTH]   imm,
  output [`REG_NUM]        reg_write_out,

  // reg_file to id/ex
  output [`COMMON_WIDTH]   src1,
  output [`COMMON_WIDTH]   src2
  );

  wire [`REG_NUM] decoder_out_rs[2:1];

  id_decoder decoder(
    .rst(rst),
    .inst(inst),

    // to id/ex
    .write_alu_result_tag(write_alu_result_tag),
    .alu_type(alu_type),
    .src_tag(src_tag),
    .extended_imm(imm),
    .reg_write_out(reg_write_out),

    // to reg_file
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2])
    );

  // reset tags and reg_write to 0 at the begining of every period
  reg tag_forward_ex;
  reg tag_forward_mem;
  reg [`REG_NUM]      reg_write;
  reg [`COMMON_WIDTH] data_write;
  // reset tags
  always @ (posedge clk) begin
    tag_forward_ex  <= 0;
    tag_forward_mem <= 0;
    reg_write       <= 0;
  end

  // forwarding
  // triggers
  always @ (reg_forward_ex  or data_forward_ex)  tag_forward_ex  = 1;
  always @ (reg_forward_mem or data_forward_mem) tag_forward_mem = 1;

  always @ (tag_forward_ex or tag_forward_mem) begin
      if (tag_forward_ex) begin
        reg_write  <= reg_forward_ex;
        data_write <= data_forward_ex;
      end else if (tag_forward_mem) begin
        reg_write  <= reg_forward_mem;
        data_write <= data_forward_mem;
      end
  end

  id_reg_file reg_file(
    .rst(rst),

    // from decoder
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2]),

    // from wb
    .reg_write(reg_write),
    .data_write(data_write),

    // to id/ex
    .src1(src1),
    .src2(src2)
  );

endmodule // pipeline_id
