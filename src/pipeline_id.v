`include "define.h"

module pipeline_id (
  input rst,

  // from if/id
  input [`COMMON_WIDTH] inst,

  // from forwarding
  input [`REG_NUM_WIDTH]   reg_forward_ex,
  input [`REG_NUM_WIDTH]   reg_forward_mem,
  input [`COMMON_WIDTH]    data_forward_ex,
  input [`COMMON_WIDTH]    data_forward_mem,

  // decoder to id/ex
  output [`ALU_TYPE_WIDTH]  alu_type,
  output                    imm_tag,
  output [`COMMON_WIDTH]    imm,
  output [`REG_NUM_WIDTH]   reg_write_out,
  output [`STAGE_NUM_WIDTH] forwarding_at,

  // reg_file to id/ex
  output [`COMMON_WIDTH]   src1,
  output [`COMMON_WIDTH]   src2
  );

  wire [`REG_NUM_WIDTH] decoder_out_rs[2:1];

  id_decoder decoder(
    .rst(rst),
    .inst(inst),

    // to id/ex
    .alu_type(alu_type),
    .imm_tag(imm_tag),
    .extended_imm(imm),
    .reg_write_out(reg_write_out),
    .forwarding_at(forwarding_at),

    // to reg_file
    .rs1(decoder_out_rs[1]),
    .rs2(decoder_out_rs[2])
    );

  reg tag_forward_ex;
  reg tag_forward_mem;
  reg [`REG_NUM_WIDTH] reg_write;
  reg [`COMMON_WIDTH]  data_write;

  // forwarding
  // triggers
  always @ (reg_forward_ex  or data_forward_ex)  tag_forward_ex  = 1;
  always @ (reg_forward_mem or data_forward_mem) tag_forward_mem = 1;

  always @ (tag_forward_ex or tag_forward_mem) begin
      if (tag_forward_ex) begin
        reg_write  <= reg_forward_ex;
        data_write <= data_forward_ex;
        tag_forward_ex <= 0;
      end else if (tag_forward_mem) begin
        reg_write  <= reg_forward_mem;
        data_write <= data_forward_mem;
        tag_forward_mem <= 0;
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
