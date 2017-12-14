`include  "define.h"

module alu (
  input rst,
  input clk,

  input wire[`ALU_OPCODE_WIDTH] opcode,
  input wire[`REG_WIDTH] src1,
  input wire[`REG_WIDTH] src2,
  output reg[`REG_WIDTH] result,

  output reg busy,
  output reg done
  );

  always @ ( posedge clk or posedge rst ) begin
    if (rst) begin
      result <= 0;
      busy   <= 0;
      done   <= 0;
    end else begin
      done <= 1;
      busy <= 0; // ??
      case (opcode)
        `ALU_ADD:	result <= src1 + src2;
  			`ALU_ADDU:	result <= src1 + src2;
  			`ALU_SUB:	result <= src1 - src2;
  			`ALU_SUBU:	result <= src1 - src2;
  			`ALU_AND:	result <= src1 & src2;
  			`ALU_OR:	result <= src1 | src2;
  			`ALU_NOR:	result <= ~(src1 | src2);
  			`ALU_XOR:	result <= src1 ^ src2;
  			`ALU_SLL:	result <= src2 << src1[4:0];
  			`ALU_SRL:	result <= src2 >> src1[4:0];
  			`ALU_SRA:	result <= $signed(src2) >>> src1[4:0];
  			`ALU_ROR:	result <= (src2 >> src1[4:0]) | (src2 << (32-src1[4:0]));
  			`ALU_SEQ:	result <= src1 == src2 ? 32'b1 : 32'b0;
  			`ALU_SLT:	result <= $signed(src1) < $signed(src2) ? 32'b1 : 32'b0;
  			`ALU_SLTU:	result <= src1 < src2 ? 32'b1 : 32'b0;
        default: done <= 0;
      endcase
    end
  end

endmodule // alu
