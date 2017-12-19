`include "define.h"

// the decoder part has not been tested
module pipeline_id_tb;
  reg rst;
  reg [`COMMON_WIDTH] inst;

  reg                  ce_forward_ex;
  reg [`REG_NUM_WIDTH] reg_forward_ex;
  reg [`COMMON_WIDTH]  data_forward_ex;
  reg                  ce_forward_mem;
  reg [`REG_NUM_WIDTH] reg_forward_mem;
  reg [`COMMON_WIDTH]  data_forward_mem;

  wire [`COMMON_WIDTH] src;
  wire [`COMMON_WIDTH] src2;

  pipeline_id DUT(
    .rst(rst),
    .inst(inst),

    .ce_forward_ex(ce_forward_ex),
    .reg_forward_ex(reg_forward_ex),
    .data_forward_ex(data_forward_ex),
    .ce_forward_mem(ce_forward_mem),
    .reg_forward_mem(reg_forward_mem),
    .data_forward_mem(data_forward_mem),

    .src1(src),
    .src2(src2)
    );

  task print_regs;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1)
        if (DUT.reg_file.regs[i] !== 0)
          $display("regs[%d] = %d", i, DUT.reg_file.regs[i]);
    end
  endtask

  task naive_test;
    begin
      rst = 1;
      #10;
      rst = 0;
      // print_regs;

      DUT.reg_file.regs[1] = 3;
      #5;
      // print_regs;

      // x2 = x1 + x1
      inst = 32'b00000000000100001000000100110011;
      #5;
      // print_regs;
      $display("src = %d, ans = 3", src);
      #5;
      {reg_forward_ex, data_forward_ex} <= {5'd1, 32'd10};
      #10;
      $display("src = %d, ans = 10", src);
      // print_regs;
      #100;
    end
  endtask

  `define FORWARD(STAGE, REG, DATA, ANS) \
    {reg_forward_``STAGE``, data_forward_``STAGE``} = {5'd1, REG, DATA}; \
    ce_forward_``STAGE`` = 1; \
    #10; \
    print_regs; \
    #5;

  initial begin
    // naive_test;
    rst = 1;
    #10;
    rst = 0;
    ce_forward_ex  = 0;
    ce_forward_mem = 0;

    inst = 32'b00000000000100010000000100110011;
    #5;
    `FORWARD(mem, 5'd1, 32'd10, 10);
    `FORWARD(ex,  5'd1, 32'd20, 20);
    `FORWARD(mem, 5'd1, 32'd10, 20);
    `FORWARD(mem, 5'd2, 32'd10, 20);
    // ans:
    // regs[          1] =         10
    // regs[          1] =         20
    // regs[          1] =         20
    // regs[          1] =         20
    // regs[          2] =         10

    #100
    $finish;
  end

endmodule //pipeline_id_tb
