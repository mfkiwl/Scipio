`include "define.h"

// the decoder should complete its task in the
// first half period
module pipeline_id (
  input rst,
  input clk, // only used to synchronize reg_file

  // from if/id
  input [`COMMON_WIDTH] inst,

  // from forwarding
  input [`REG_NUM]      reg_write,
  input [`COMMON_WIDTH] data_write,

  // decoder to id/ex
  output                   write_alu_result_tag,
  output [`ALU_TYPE_WIDTH] alu_type,
  output [2:0]             src_tag,
  output [`COMMON_WIDTH]   imm,
  output [`REG_NUM]        reg_write_out,

  // reg_file to id/ex
  output                   modi1,
  output [`COMMON_WIDTH]   src1,
  output                   modi2,
  output [`COMMON_WIDTH]   src2
  );

  wire [`REG_NUM] decoder_out_rs[2:1];
  wire [`REG_NUM] decoder_out_rd;

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
    .rd(decoder_out_rd),
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2])
    );

  id_reg_file reg_file(
    .clk(clk),
    .rst(rst),

    // from decoder
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2]),
    .rd(decoder_out_rd),

    // from wb
    .reg_write(reg_write),
    .data_write(data_write),

    // to id/ex
    .src1(src1),
    .src2(src2),
    .modi1(modi1),
    .modi2(modi2)
  );

endmodule // pipeline_id
