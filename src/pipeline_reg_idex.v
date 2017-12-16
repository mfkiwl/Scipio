`include "define.h"

module pipeline_reg_idex (
  input rst,
  input clk,

  input [`ALU_TYPE_WIDTH] alu_type_in,
  input [`REG_NUM]        rd_in,

  input [`COMMON_WIDTH]   src1_in,
  input [`COMMON_WIDTH]   src2,
  input                   imm_tag,
  input [`COMMON_WIDTH]   imm,
  input                   write_alu_result_tag_in,

  // to ex
  output reg [`ALU_TYPE_WIDTH] alu_type,
  output reg [`COMMON_WIDTH]   src1,
  output reg [`COMMON_WIDTH]   src2_imm,

  // to ex/men
  output reg [`REG_NUM]   rd,
  output reg              write_alu_result_tag
  );

  // reset
  always @ (posedge rst) begin
    alu_type <= 0;
    src1     <= 0;
    src2_imm <= 0;
    rd       <= 0;
  end

  always @ (posedge clk) begin
    alu_type <= alu_type_in;
    src1     <= src1_in;
    rd       <= rd_in;
    write_alu_result_tag <= write_alu_result_tag_in;
    if (imm_tag)
      src2_imm <= imm;
    else
      src2_imm <= src2;
  end

endmodule // pipeline_reg_idex
