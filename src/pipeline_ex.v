// TODO

`include "define.h"

module pipeline_ex (
  input clk,
  input rst,

  input [`ALU_OPCODE_WIDTH] alu_opcode,
  input [31:0] src1,
  input [31:0] src2,

  output [31:0] wb_data
  );

  wire [31:0] alu_result;

  alu ALU(
    .rst(rst),
    .clk(clk),

    .opcode(alu_opcode),
    .src1(src1),
    .src2(src2),

    .result(wb_data)
    );

endmodule // pipeline_ex
