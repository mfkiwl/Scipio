`include "define.h"

// write in the first half period
// read in the second half period
// CAUTION: reg_write & data_write should be synchronized
// CAUTION: if there is no rd, set rd = 0

module id_reg_file (
  input rst,
  input clk, // just the negedge is used

  input wire [`REG_NUM]        rs1,
  output reg [`COMMON_WIDTH]   src1,
  output reg                   modi1,

  input wire [`REG_NUM]        rs2,
  output reg [`COMMON_WIDTH]   src2,
  output reg                   modi2,

  input wire [`REG_NUM]       rd,

  // write back
  input [`REG_NUM]        reg_write,
  input [`COMMON_WIDTH]   data_write
  );

  reg [`COMMON_WIDTH]   regs[31:1];
  reg [`MAX_MODI_WIDTH] modified[31:1];

  integer i;
  always @ (posedge rst) begin
    for (i = 1; i < 32; i = i + 1) begin
      regs[i] <= 0;
      modified[i] <= 0;
    end
  end

  // write back & update modified[reg_write]
  always @ (reg_write or data_write) begin
    if (reg_write != 0) begin
      regs[reg_write]     <= data_write;
      modified[reg_write] <= modified[reg_write] - 1;
    end
  end

  // read & update modified[rd]
  always @ (negedge clk) begin
    src1 <= (rs1 == 0) ? 0 : regs[rs1];
    src2 <= (rs2 == 0) ? 0 : regs[rs2];
    if (rd !== 0)
      modified[rd] <= modified[rd] + 1;
    modi1 <= (modified[src1] == 0) ? 0 : 1;
    modi2 <= (modified[src2] == 0) ? 0 : 1;
  end

endmodule // id_reg_file
