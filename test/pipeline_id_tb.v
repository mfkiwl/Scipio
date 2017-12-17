`include "define.h"

// the decoder part has not been tested
module pipeline_id_tb;
  reg rst;
  reg [`COMMON_WIDTH] inst;

  reg [`REG_NUM_WIDTH] reg_forward;
  reg [`COMMON_WIDTH]  data_forward;

  wire [`COMMON_WIDTH] src;

  pipeline_id DUT(
    .rst(rst),
    .inst(inst),

    .reg_forward_ex(reg_forward),
    .data_forward_ex(data_forward),

    .src1(src)
    );

  task print_regs;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1)
        if (DUT.reg_file.regs[i] !== 0)
          $display("regs[%d] = %d", i, DUT.reg_file.regs[i]);
    end
  endtask

  initial begin
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
    {reg_forward, data_forward} <= {5'd1, 32'd10};
    #10;
    $display("src = %d, ans = 10", src);
    print_regs;
    #100;
    $finish;
  end

endmodule //pipeline_id_tb
