`include "define.h"

module cpu_core (
  input clk,
  input rst,

  // DEBUG
  input  [31:0] debug_inst,
  output [31:0] wb_data
  );

  /////////////////////////////////
  /////////// ID -> EX ////////////
  wire [`ALU_OPCODE_WIDTH] id_ex_alu_opcode;
  wire [31:0] id_ex_src1;
  wire [31:0] id_ex_src2;
  /////////////////////////////////


  pipeline_id id(
    .clk(clk),
    .rst(rst),
    .inst(debug_inst),

    .alu_opcode(id_ex_alu_opcode),
    .src1(id_ex_src1),
    .src2(id_ex_src2)
    );

  pipeline_ex ex(
    .clk(clk),
    .rst(rst),

    .alu_opcode(id_ex_alu_opcode),
    .src1(id_ex_src1),
    .src2(id_ex_src2),

    // DEBUG
    .wb_data(wb_data)
    );



endmodule // cpu_core
