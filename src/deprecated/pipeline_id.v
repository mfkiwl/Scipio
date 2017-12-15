// todo

`include "define.h"

module pipeline_id (
  input clk,
  input rst,

  input [31:0] inst,

  output reg[31:0] src1,
  output reg[31:0] src2,

  output reg[`ALU_OPCODE_WIDTH] alu_opcode,
  output reg[4:0] dreg, // ??

  // DEBUG
  output reg[2:0] decoded_type
  );

  reg [4:0] sreg1;
  reg [4:0] sreg2;

  reg_file regs(
    .rst(rst),
    .read_num1(sreg1),
    .read_num2(sreg2),
    .read_res1(src1),
    .read_res2(src2)
    );

  task reset;
    begin
      decoded_type <= -1;
    end
  endtask

  task decode_rtype;
    begin
      decoded_type <= `R_TYPE; // DEBUG
      dreg   <= inst[`POS_RD]; // ??
      sreg1  <= inst[`POS_RS1];
      sreg2  <= inst[`POS_RS2];
      if (inst[`POS_FUNCT3] == `ADD_FUNCT3
          && inst[`POS_FUNCT7] == `ADD_FUNCT7)
          alu_opcode <= `ALU_ADD;
    end
  endtask

  task decode_itype;
    begin
      decoded_type <= `I_TYPE; // DEBUG
      dreg <= inst[`POS_RD];
      sreg1 <= inst[`POS_RS1];
      src1  <= $signed(inst[`POS_IMM]);

    end
  endtask

  // decode
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      case (inst[`POS_OPCODE])
        `R_TYPE_OPCODE: decode_rtype;
        default: decoded_type <= 1;
      endcase
    end
  end

endmodule // pipeline_id
