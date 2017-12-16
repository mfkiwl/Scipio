`include "define.h"

module cpu_core (
  input wire rst,
  input wire clk
  );

  //////////////////////////
  //////////DEBUG///////////
  reg [`COMMON_WIDTH] inst;
  //////////////////////////

  wire [`COMMON_WIDTH] ifid_out_inst;

  pipeline_reg_ifid ifid(
    .rst(rst),
    .clk(clk),

    // input
    .inst_in(inst),

    // output
    .inst_out(ifid_out_inst)
    );

  wire [`ALU_TYPE_WIDTH] id_out_alu_type;
  wire [`REG_NUM]        id_out_rd;
  wire [`COMMON_WIDTH]   id_out_src1;
  wire [`COMMON_WIDTH]   id_out_src2;
  wire [`COMMON_WIDTH]   id_out_imm;
  wire                   id_out_imm_tag;
  wire                   id_out_write_alu_result_tag;
  // wires from memwb
  wire [`REG_NUM]        memwb_out_reg_write;
  wire [`COMMON_WIDTH]   memwb_out_data_write;

  pipeline_id id(
    .rst(rst),

    // input
    .inst(ifid_out_inst),
    .reg_write(memwb_out_reg_write),
    .data_write(memwb_out_data_write),

    // output
    .alu_type(id_out_alu_type),
    .rd(id_out_rd),
    .src1(id_out_src1),
    .src2(id_out_src2),
    .imm_tag(id_out_imm_tag),
    .imm(id_out_imm),
    .write_alu_result_tag(id_out_write_alu_result_tag)
    );

  wire [`ALU_TYPE_WIDTH] idex_out_alu_type;
  wire [`COMMON_WIDTH]   idex_out_src1;
  wire [`COMMON_WIDTH]   idex_out_src2_imm;
  wire [`REG_NUM]        idex_out_rd;
  wire                   idex_out_write_alu_result_tag;

  pipeline_reg_idex idex(
    .rst(rst),
    .clk(clk),

    // input
    .alu_type_in(id_out_alu_type),
    .rd_in(id_out_rd),
    .src1_in(id_out_src1),
    .src2(id_out_src2),
    .imm_tag(id_out_imm_tag),
    .imm(id_out_imm),
    .write_alu_result_tag_in(id_out_write_alu_result_tag),

    // output
    .alu_type(idex_out_alu_type),
    .src1(idex_out_src1),
    .src2_imm(idex_out_src2_imm),
    // to ex/mem
    .rd(idex_out_rd),
    .write_alu_result_tag(idex_out_write_alu_result_tag)
    );

  wire [`COMMON_WIDTH] ex_out_result;

  pipeline_ex ex(
    .rst(rst),

    // input
    .alu_type(idex_out_alu_type),
    .src1(idex_out_src1),
    .src2(idex_out_src2_imm),

    // output
    .result(ex_out_result)
    );

  wire [`COMMON_WIDTH] exmem_out_result;
  wire [`REG_NUM]      exmem_out_reg_write;
  wire                 exmem_out_write_alu_result_tag;

  pipeline_reg_exmem exmem(
    .rst(rst),
    .clk(clk),

    // input
    .result_in(ex_out_result),
    .rd(idex_out_rd),
    .write_alu_result_tag_in(idex_out_write_alu_result_tag),

    // output
    .result(exmem_out_result), // to ex/mem too
    // to ex/mem
    .reg_write(exmem_out_reg_write),
    .write_alu_result_tag(exmem_out_write_alu_result_tag)
    );

  // the wires from memwb are declared before id
  pipeline_reg_memwb memwb(
    .rst(rst),
    .clk(clk),

    // input
    .reg_write_in(exmem_out_reg_write),
    .alu_result(exmem_out_result),
    .write_alu_result_tag(exmem_out_write_alu_result_tag),

    // output
    .reg_write(memwb_out_reg_write),
    .data_write(memwb_out_data_write)
    );

endmodule // cpu_core
