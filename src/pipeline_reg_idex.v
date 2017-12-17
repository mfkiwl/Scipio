`include "define.h"

module pipeline_reg_idex (
  input rst,
  input clk,

  // from id
  input                   write_alu_result_tag_in,
  input [`ALU_TYPE_WIDTH] alu_type_in,
  input [2:0]             src_tag,
  input [`COMMON_WIDTH]   imm_in,
  input [`REG_NUM]        reg_write_in,

  input                   modi1_in,
  input [`COMMON_WIDTH]   src1_in,
  input                   modi2_in,
  input [`COMMON_WIDTH]   src2_in,

  // to ex
  output reg [`ALU_TYPE_WIDTH] alu_type,
  output reg [`COMMON_WIDTH]   src1,
  output reg [`COMMON_WIDTH]   src2,

  // to ex/men
  output reg [`REG_NUM]   reg_write,
  output reg              write_alu_result_tag,

  // (back) to if/id
  output reg              block
  );

  task reset;
    begin
      alu_type <= `ALU_NOP;
      src1 <= 0;
      src2 <= 0;
      reg_write   <= 0;
      write_alu_result_tag <= 0;
      block <= 0;
    end
  endtask

  // reset
  always @ (posedge rst) begin
    reset;
  end

  always @ (posedge clk) begin
    // to ex
    alu_type <= alu_type_in;
    src1     <= src1_in;
    src2     <= src_tag[0] ? imm_in : src2_in;

    // to ex/mem
    reg_write <= reg_write_in;
    write_alu_result_tag <= write_alu_result_tag_in;

    if ((src_tag[1] && modi1_in) || (src_tag[2] && modi2_in)) begin
      reset;
      block <= 1'b1;
    end
  end

endmodule // pipeline_reg_idex
