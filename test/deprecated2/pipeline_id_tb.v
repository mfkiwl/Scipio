/*
`include "define.h"

module pipeline_id_tb;
  reg clk;
  // input
  reg rst;
  reg [`COMMON_WIDTH] inst;
  reg [`REG_NUM]      reg_write;
  reg [`COMMON_WIDTH] data_write;

  // output
  wire [`ALU_TYPE_WIDTH] alu_type;
  wire [`REG_NUM]        rd;
  wire [`COMMON_WIDTH]   src1;
  wire [`COMMON_WIDTH]   src2;

  pipeline_id DUT(
    .rst(rst),
    .inst(inst),
    .reg_write(reg_write),
    .data_write(data_write),

    .alu_type(alu_type),
    .rd(rd),
    .src1(src1),
    .src2(src2)
    );

  // clock
  initial begin
    clk = 1'b0;
    rst = 1'b1;
    repeat(4) #30 clk = ~clk;
    rst = 1'b0;
    forever #30 clk = ~clk;
  end

  initial begin
    $display("test: pipeline_id");
    @(negedge rst);
    // without wb
    inst = $random;
    inst[`POS_OPCODE] = `R_TYPE_OPCODE;
    inst[`POS_FUNCT3] = 3'b000;
    inst[`POS_FUNCT7] = 7'b0000000;
    @(posedge clk);
    #10
    // ans = 0, 0
    $display("src1 = %d, src2 = %d", src1, src2);

    // with wb
    inst = $random;
    inst[`POS_OPCODE] = `R_TYPE_OPCODE;
    inst[`POS_FUNCT3] = 3'b000;
    inst[`POS_FUNCT7] = 7'b0000000;
    reg_write  <= inst[`POS_RS1];
    data_write <= 12;
    @(posedge clk);
    #10
    // ans = 12, 0
    $display("src1 = %d, src2 = %d", src1, src2);
    $display("finish: pipeline_id");
    $finish;
  end


endmodule // pipeline_id_tb
*/
