`include "define.h"

module pipeline_ex (
  input rst,

  input [`ALU_TYPE_WIDTH] alu_type,
  input [`COMMON_WIDTH]   src1,
  input [`COMMON_WIDTH]   src2, // src2 or imm

  output [`COMMON_WIDTH] result
  );

  ex_alu alu(
    .rst(rst),

    .alu_type(alu_type),
    .src1(src1),
    .src2(src2),

    .result(result)
    );

endmodule // pipeline_ex
