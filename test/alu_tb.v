`include "define.h"

module alu_tb ();

  reg clk, rst;
  reg [`REG_WIDTH] src1, src2;
  wire [`REG_WIDTH] res;
  reg [`ALU_OPCODE_WIDTH] opcode;


  alu DUT(
    .clk(clk),
    .rst(rst),
    .src1(src1),
    .src2(src2),
    .opcode(opcode),
    .result(res)
    );

initial begin
  clk = 1'b0;
  rst = 1'b1;
  repeat(4) #10 clk = ~clk;
  rst = 1'b0;
  forever #10 clk = ~clk;
end

initial begin
  @(negedge rst);
  @(negedge clk);
  $display("test: alu");
  repeat(3) begin
    src1 = $urandom % 10;
    src2 = $urandom % 10;
    opcode = `ALU_ADD;
    @(negedge clk);
    if (src1 + src2 != res) begin
      $display("%d + %d != %d", src1, src2, res);
    end
  end
  $display("finish: alu");
  $finish;
end

endmodule // alu_tb
