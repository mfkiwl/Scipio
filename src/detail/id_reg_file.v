`include "define.h"

module id_reg_file (
  input rst,

  // from decoder
  input wire [`REG_NUM_WIDTH] rs1,
  input wire [`REG_NUM_WIDTH] rs2,

  // from forwarding
  input [`REG_NUM_WIDTH] reg_write,
  input [`COMMON_WIDTH]  data_write,

  // to id/ex
  output reg [`COMMON_WIDTH] src1,
  output reg [`COMMON_WIDTH] src2
  );

  // regs[0] should never be modified
  reg [`COMMON_WIDTH]    regs[31:0];

  task reset;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1)
        regs[i] <= 0;
    end
  endtask

  // read & write
  // If reg_write == rs[i] & data_write !== the original value,
  // this block will be triggered again.
  always @ ( * ) begin
    if (rst) begin
      reset;
    end else begin
      src1 <= regs[rs1];
      src2 <= regs[rs2];
      if (reg_write !== 0)
        regs[reg_write] <= data_write;
    end
  end
endmodule // id_reg_file
