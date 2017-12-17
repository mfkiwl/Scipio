`include "define.h"

module id_reg_file_tb;
  reg rst;
  reg [`REG_NUM_WIDTH] rs;

  reg [`REG_NUM_WIDTH] rd;
  reg [`COMMON_WIDTH]  data;

  wire [`COMMON_WIDTH] src;

  id_reg_file DUT(
    .rst(rst),

    .rs1(rs),
    .reg_write(rd),
    .data_write(data),

    .src1(src)
    );

  task print_regs;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1)
        if (DUT.regs[i] !== 0)
          $display("regs[%d]=%d", i, DUT.regs[i]);
    end
  endtask

  initial begin
    rst = 1;
    #10;
    rst = 0;
    #1;
    {rs, rd, data} = {5'd1, 5'd1, 32'd1};
    #10;
    $display("src = %d, ans = 1", src);
    print_regs;
  end

endmodule // id_reg_file_tb
