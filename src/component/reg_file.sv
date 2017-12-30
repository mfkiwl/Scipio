`include "common_def.h"

typedef struct {
  reg [`COMMON_WIDTH]   data;
  reg [`INST_TAG_WIDTH] tag;
} RegFileEntry;

module reg_file (
  input rst,
  input rst_tag,
  input clk,

  // write back
  input [`COMMON_WIDTH]   wd,
  input [`REG_NUM_WIDTH]  wr, // destination register
  input [`INST_TAG_WIDTH] w_tag,

  // read
  input                    ce  [1:2], // whether src_i is needed
  input  [`REG_NUM_WIDTH]  rs  [1:2],
  input                    rd_ce,
  input  [`INST_TAG_WIDTH] rd_tag,
  input  [`REG_NUM_WIDTH]  rd,

  output reg [`INST_TAG_WIDTH] tag [1:2],
  output reg [`COMMON_WIDTH]   src [1:2]
  );

  RegFileEntry regs [0:31];

  task reset;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1) begin
        regs[i].data <= 0;
        regs[i].tag  <= `TAG_INVALID;
      end
    end
  endtask

  task reset_tags;
    integer i;
    begin
      for (i = 1; i < `REG_NUM; i = i + 1)
        regs[i].tag <= `TAG_INVALID;
    end
  endtask

  always @ (posedge rst_tag) begin
    reset_tags;
  end

  // write
  always @ (w_tag or wd or wr) begin
    if (w_tag == regs[wr].tag) begin
      regs[wr].data <= wd;
      regs[wr].tag  <= `TAG_INVALID;
    end
  end

  // read
  always @ (negedge clk or posedge rst) begin
      if (rst)
        reset;
      else begin
        if (ce[1]) begin
          tag[1] <= regs[rs[1]].tag;
          src[1] <= regs[rs[1]].data;
        end
        if (ce[2]) begin
          tag[2] <= regs[rs[2]].tag;
          src[2] <= regs[rs[2]].data;
        end
        if (rd_ce && rd) begin
            regs[rd].tag <= rd_tag;
        end
      end
  end

endmodule // reg_file
