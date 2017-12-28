`include "common_def.h"

module id (
  input clk,
  input rst,
  input rst_tag,

  // from IFID
  input [`COMMON_WIDTH] inst,
  input [`COMMON_WIDTH] pc_addr,

  // fomr wb
  input [`COMMON_WIDTH]   wd,
  input [`REG_NUM_WIDTH]  wr, // destination register
  input [`INST_TAG_WIDTH] w_tag,

  // ROB information
  input [`INST_TAG_WIDTH] target,
  input                   rob_full,
  input reservation_full [0:`EX_UNIT_NUM-1],

  output reg stall_if,

  idex.out to_idex
  );

  /* wires:
   * ex_unit: [x]
   * op: [x]
   * tag[1:2]: [x, x]
   * val[1:2]: [x, x]
   * // addr:
   * target: [x]
   */

  wire [`COMMON_WIDTH]  decoder_out_imm;
  wire                  decoder_out_imm_tag;
  wire [`REG_NUM_WIDTH] decoder_out_ce [1:2];
  wire [`REG_NUM_WIDTH] decoder_out_rs [1:2];
  wire [`REG_NUM_WIDTH] decoder_out_rd;

  // stall
  always @ ( * ) begin
    if (rob_full || (reservation_full[to_idex.ex_unit])) begin
      stall_if <= 1;
      to_idex.target <= 0;
    end else begin
      stall_if <= 0;
      to_idex.target <= target;
    end
  end

  decoder id_decoder(
    .ex_unit(to_idex.ex_unit),
    .op(to_idex.op),
    .ce(decoder_out_ce),
    .rd(decoder_out_rd),
    .rs(decoder_out_rs),
    .imm(decoder_out_imm),
    .imm_tag(decoder_out_imm_tag)
    );

  wire [`COMMON_WIDTH] reg_file_out_rs2;

  reg_file id_reg_file(
    .rst(rst),
    .rst_tag(rst),
    .clk(clk),

    // wb
    .wd(wd),
    .wr(wr),
    .w_tag(w_tag),

    // read
    .ce(decoder_out_ce),
    .rs(decoder_out_rs),
    .rd(decoder_out_rd),

    .tag(to_idex.tag),
    .src('{to_idex.val[1], reg_file_out_rs2})
    );

  mux #(`COMMON_LENGTH) imm_src(
    .in1(decoder_out_imm),
    .in2(reg_file_out_rs2),
    .condition(decoder_out_imm_tag),
    .out(to_idex.val[2])
    );

endmodule // id
