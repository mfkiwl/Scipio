/*
`include "define.h"

module id_decoder_tb;
  reg rst;
  reg [`COMMON_WIDTH] inst;

  initial begin
    rst = 1'b1;
    #10;
    rst = 1'b0;
  end

  wire [`ALU_TYPE_WIDTH] alu_type;
  wire [`REG_NUM] rd;
  wire [`REG_NUM] rs1;
  wire [`REG_NUM] rs2;

  id_decoder DUT(
    .rst(rst),
    .inst(inst),

    .alu_type(alu_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2)
    );

  initial begin
    $display("test: id_decoder");
    @(negedge rst);
    repeat(3) begin
      inst = $random;
      inst[`POS_OPCODE] = `R_TYPE_OPCODE;
      inst[`POS_FUNCT3] = 3'b000;
      inst[`POS_FUNCT7] = 7'b0000000;
      #20;
      $display("inst: %b %d %d %b %d %b",
              inst[`POS_FUNCT7], inst[`POS_RS2],
              inst[`POS_RS1], inst[`POS_FUNCT3],
              inst[`POS_RD], inst[`POS_OPCODE]);
      $display("result: alu_type = %d, rs1 = %d, rs2 = %d, rd = %d",
              alu_type, rs1, rs2, rd);
      #5;
    end
    $display("finish: id_decoder");
    $finish;
  end


endmodule // id_decoder_tb
*/
