`include "define.h"

module cpu_core_tb ();
  reg clk;
  reg rst;
  wire [31:0] result;
  reg [31:0] inst;

  cpu_core DUT(
    .clk(clk),
    .rst(rst),

    .debug_inst(inst),

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
    $display("test: cpu core");
    @(negedge rst);
    inst = $random;
    inst[`POS_OPCODE] = `R_TYPE_OPCODE;
    inst[`POS_FUNCT3] = `ADD_FUNCT3;
    inst[`POS_FUNCT7] = `ADD_FUNCT7;
    repeat(5) begin
    @(posedge clk);
    #5;
    $display("reg[%d] + reg[%d] = %d", inst[`POS_RS1], inst[`POS_RS2], result);
    end
    $display("finish: cpu core");
    $finish;
  end


endmodule // cpu_core_tb
