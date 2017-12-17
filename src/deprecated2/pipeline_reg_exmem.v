`include "define.h"

module pipeline_reg_exmem (
  input rst,
  input clk,

  input [`COMMON_WIDTH] result_in,
  input [`REG_NUM]      rd,
  input                 write_alu_result_tag_in,

  output reg [`COMMON_WIDTH] result,
   // to pipeline_reg_memwb
  output reg [`REG_NUM]      reg_write,
  output reg                 write_alu_result_tag
  );

  always @ (posedge clk) begin
    // $display("exmem: tag = %d", write_alu_result_tag_in);
    reg_write <= rd;
    result    <= result_in;
    write_alu_result_tag <= write_alu_result_tag_in;
  end

  // reset
  always @ (posedge rst) begin
    reg_write  <= 0;
    write_alu_result_tag <= 1'b0;
  end

endmodule // pipeline_reg_exmem
