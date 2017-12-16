`include "define.h"

module ex_alu (
  input rst,

  input [`ALU_TYPE_WIDTH] alu_type,
  input [`COMMON_WIDTH]   src1,
  input [`COMMON_WIDTH]   src2,

  output reg [`COMMON_WIDTH] result
  );

  always @ (posedge rst) begin
    result <= 0;
  end

  always @ ( * ) begin
  case (alu_type)
    `ALU_ADD:	 result <= src1 + src2;
    `ALU_ADDU: result <= src1 + src2;
    `ALU_SUB:	 result <= src1 - src2;
    `ALU_SUBU: result <= src1 - src2;
    `ALU_AND:	 result <= src1 & src2;
    `ALU_OR:	 result <= src1 | src2;
    `ALU_NOR:	 result <= ~(src1 | src2);
    `ALU_XOR:	 result <= src1 ^ src2;
    `ALU_SLL:	 result <= src2 << src1[4:0];
    `ALU_SRL:	 result <= src2 >> src1[4:0];
    `ALU_SRA:	 result <= $signed(src2) >>> src1[4:0];
    `ALU_ROR:	 result <= (src2 >> src1[4:0]) | (src2 << (32-src1[4:0]));
    `ALU_SEQ:	 result <= src1 == src2 ? 32'b1 : 32'b0;
    `ALU_SLT:	 result <= $signed(src1) < $signed(src2) ? 32'b1 : 32'b0;
    `ALU_SLTU: result <= src1 < src2 ? 32'b1 : 32'b0;
    default:;
  endcase
  end

endmodule // ex_alu
