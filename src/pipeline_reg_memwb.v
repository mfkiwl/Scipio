`include "define.h"

module pipeline_reg_memwb (
  input rst,
  input clk,

  input [`REG_NUM]      reg_write_in,
  input [`COMMON_WIDTH] alu_result,
  input [`COMMON_WIDTH] mem_result,
  input                 write_alu_result_tag,

  output reg [`REG_NUM]      reg_write,
  output reg [`COMMON_WIDTH] data_write
  );

  always @ (posedge clk) begin
    if (reg_write_in !== 0) begin
      reg_write <= reg_write_in;
      if (write_alu_result_tag)
        data_write <= alu_result;
      else
        data_write <= mem_result;
    end
  end

  // reset
  always @ (posedge rst) begin
    reg_write  <= 0;
    data_write <= 0;
  end

endmodule // pipeline_reg_memwb
