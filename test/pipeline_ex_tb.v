`include "define.h"

module pipeline_ex_tb ();
  reg clk;
  reg rst;

  reg [`ALU_OPCODE_WIDTH] alu_opcode;
  reg [31:0] src1;
  reg [31:0] src2;
  wire [31:0] result;

  pipeline_ex DUT(
    .clk(clk),
    .rst(rst),
    .alu_opcode(alu_opcode),
    .src1(src1),
    .src2(src2),
    .wb_data(result)
    );

    // clock
    initial begin
      clk = 1'b0;
      rst = 1'b1;
      repeat(4) #10 clk = ~clk;
      rst = 1'b0;
      forever #10 clk = ~clk; // generate a clock
    end

    initial begin
      $display("test: ex");
      @(negedge rst);
      src1 <= $urandom % 10;
      src2 <= $urandom % 10;
      alu_opcode <= `ALU_ADD;
      @(posedge clk);
      #5;
      if (result != src1 + src2)
        $display("%d + %d != %d", src1, src2, result);
      $display("finish: ex");
      $finish;
    end

endmodule // pipeline_ex_tb
