`include "define.h"

// TODO: test

module id_reg_file (
  input rst,

  input wire [`REG_NUM]       rs1,
  output reg [`COMMON_WIDTH]  src1,

  input wire [`REG_NUM]       rs2,
  output reg [`COMMON_WIDTH]  src2,

  input [`REG_NUM]        rd,
  input [`COMMON_WIDTH]   data
  );

  reg [`COMMON_WIDTH] regs[31:1];

  integer i;
  always @ (posedge rst) begin
    for (i = 0; i < 32; i = i + 1)
      regs[i] <= 0;
  end

  // write
  always @ ( * ) begin
    if (rd !== 0)
      regs[rd] <= data;
  end

  // read
  always @ ( * ) begin
    src1 = (rs1 == 0) ? 0 : regs[rs1];
    src2 = (rs2 == 0) ? 0 : regs[rs2];
  end

endmodule // id_reg_file
