`include "define.h"

module pipeline_id (
  input rst,

  input [`COMMON_WIDTH] inst,

  input [`REG_NUM]      reg_write,
  input [`COMMON_WIDTH] data_write,

  output [`ALU_TYPE_WIDTH] alu_type,
  output                   write_alu_result_tag,
  output [`REG_NUM]        rd,
  output [`COMMON_WIDTH]   src1,
  output [`COMMON_WIDTH]   src2,
  output                   imm_tag,
  output [`COMMON_WIDTH]   imm
  );

  wire [`REG_NUM] decoder_out_rs[2:1];

  id_decoder decoder(
    .rst(rst),
    .inst(inst),

    .alu_type(alu_type),
    .rd(rd),
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2]),
    .extended_imm(imm),
    .imm_tag(imm_tag),
    .write_alu_result_tag(write_alu_result_tag)
    );

  id_reg_file reg_file(
    .rst(rst),

    .rs1(decoder_out_rs[1]),
    .src1(src1),
    .rs2(decoder_out_rs[2]),
    .src2(src2),

    .reg_write(reg_write),
    .data_write(data_write)
  );

endmodule // pipeline_id
