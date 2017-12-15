`include "define.h"

module cpu_core (
  input wire rst,
  input wire clk
  );

  //////////////////////////
  //////////DEBUG///////////
  reg [`COMMON_WIDTH] inst;
  reg [`REG_NUM]      reg_write;
  reg [`COMMON_WIDTH] data_write;
  //////////////////////////

  wire [`COMMON_WIDTH] ifid_out_inst;

  pipeline_reg_ifid ifid(
    .rst(rst),
    .clk(clk),

    .inst_in(inst),

    .inst_out(ifid_out_inst)
    );

  wire [`ALU_TYPE_WIDTH] id_out_alu_type;
  wire [`REG_NUM]        id_out_rd;
  wire [`COMMON_WIDTH]   id_out_src1;
  wire [`COMMON_WIDTH]   id_out_src2;
  wire                   id_out_imm_tag;
  wire [`COMMON_WIDTH]   id_out_imm;

  pipeline_id id(
    .rst(rst),

    .inst(ifid_out_inst),
    .reg_write(reg_write),
    .data_write(data_write),

    .alu_type(id_out_alu_type),
    .rd(id_out_rd),
    .src1(id_out_src1),
    .src2(id_out_src2),
    .imm_tag(id_out_imm_tag),
    .imm(id_out_imm)
    );

  wire [`ALU_TYPE_WIDTH] idex_out_alu_type;
  wire [`COMMON_WIDTH]   idex_out_src1;
  wire [`COMMON_WIDTH]   idex_out_src2_imm;
  wire [`REG_NUM]        idex_out_rd;

  pipeline_reg_idex idex(
    .rst(rst),
    .clk(clk),

    .alu_type_in(id_out_alu_type),
    .rd_in(id_out_rd),
    .src1_in(id_out_src1),
    .src2(id_out_src2),
    .imm_tag(id_out_imm_tag),
    .imm(id_out_imm)
    );

endmodule // cpu_core
