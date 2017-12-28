`include "common_def.h"

module decoder (
  input [`COMMON_WIDTH] inst,
  input [`COMMON_WIDTH] pc_addr,

  output [`EX_UNIT_NUM_WIDTH] ex_unit,

  output [`INST_OP_WIDTH] op,
  output [`COMMON_WIDTH]  imm,
  output                  imm_tag,

  // to reg_file
  output                  ce [1:2],
  output [`REG_NUM_WIDTH] rs [1:2],
  output [`REG_NUM_WIDTH] rd
  );

  // TODO

endmodule : decoder
