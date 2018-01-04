`include "common_def.h"

typedef struct {
  reg [`COMMON_WIDTH]   data;
  reg [`INST_TAG_WIDTH] tag;
} RegFileEntry;

module reg_file (
  input rst,
  input rst_tag,
  input clk,

  wb_id_inf.id  wb,

  input [`INST_TAG_WIDTH]       rd_tag,
  decoder_reg_file_inf.reg_file in,
  reg_file_result_inf.reg_file  out
  );

  RegFileEntry regs [0:31];

  // read
  always @ (negedge clk or posedge rst) begin
      if (rst) reset;
      else begin
        out.tag[1] = regs[in.rs[1]].tag;
        out.val[1] = regs[in.rs[1]].data;
        out.tag[2] = regs[in.rs[2]].tag;
        out.val[2] = regs[in.rs[2]].data;
        if (in.rd_en && in.rd)
            regs[in.rd].tag = rd_tag;
      end
  end

  // write back
  always @ ( * ) begin
    if (wb.tag == regs[wb.rd].tag) begin
      regs[wb.rd].data = wb.data;
      regs[wb.rd].tag  = `TAG_INVALID;
    end
  end

  task reset_tags;
    integer i;
    begin
      for (i = 1; i < `REG_NUM; i = i + 1)
        regs[i].tag <= `TAG_INVALID;
    end
  endtask
  always @ (posedge rst_tag) reset_tags;

  task reset;
    integer i;
    begin
      for (i = 0; i < `REG_NUM; i = i + 1) begin
        regs[i].data <= 0;
        regs[i].tag  <= `TAG_INVALID;
      end
    end
  endtask
endmodule // reg_file
