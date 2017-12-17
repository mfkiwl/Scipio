`include "define.h"

module id_reg_file (
  input rst,

  // from decoder
  input wire [`REG_NUM] rs1,
  input wire [`REG_NUM] rs2,

  // from forwarding
  input [`REG_NUM]      reg_write,
  input [`COMMON_WIDTH] data_write,

  // to id/ex
  output reg [`COMMON_WIDTH] src1,
  output reg [`COMMON_WIDTH] src2
  );

  reg [`COMMON_WIDTH]    regs[31:0];

  integer i;
  always @ (posedge rst) begin
    for (i = 0; i < 32; i = i + 1) begin
      regs[i] <= 0;
    end
  end

  // read & write
  always @ ( * ) begin
    src1 <= regs[rs1];
    src2 <= regs[rs2];
    if (reg_write !== 0) begin
      regs[reg_write] <= data_write;
      if (reg_write == rs1)
        src1 <= data_write;
      if (reg_write == rs2)
        src2 <= data_write;
    end
  end
endmodule // id_reg_file
