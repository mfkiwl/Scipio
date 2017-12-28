`include "common_def.h"

module pif (
  input clk,
  input rst,
  input stall,

  input                 jump_ce,
  input [`COMMON_WIDTH] jump_pc,

  output [`COMMON_WIDTH] inst,
  output [`COMMON_WIDTH] pc_addr
  );

  wire [`COMMON_WIDTH] mux_out_next_pc;
  wire [`COMMON_WIDTH] pc_out_pc_addr;
  wire [`COMMON_WIDTH] pc_addr_plus4 = pc_out_pc_addr + 4;
  assign pc_addr = pc_out_pc_addr;

  pc_reg pc(
    .stall(stall),
    .clk(clk),
    .rst(rst),

    .next_pc(mux_out_next_pc),

    .pc_addr(pc_out_pc_addr)
    );

  mux #(`COMMON_LENGTH) jump_plus4(
    .in1(jump_pc),
    .in2(pc_addr_plus4),
    .condition(jump_ce),
    .out(mux_out_next_pc)
    );

  // TODO: inst rom

endmodule : pif
