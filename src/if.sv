`include "common_def.h"

interface pif_ifid_inf;
  bit [`COMMON_WIDTH] inst;
  bit [`COMMON_WIDTH] pc_addr;

  modport pif (output inst, pc_addr);
  modport ifid (input inst, pc_addr);
endinterface

module pif (
  input clk,
  input rst,

  input stall,
  input                 jump_ce,
  input [`COMMON_WIDTH] jump_pc,

  pif_ifid_inf.pif to_idif
  );

  wire [`COMMON_WIDTH] mux1_out_next_pc;
  wire [`COMMON_WIDTH] mux2_out_next_pc;
  wire [`COMMON_WIDTH] pc_out_pc_addr;
  wire [`COMMON_WIDTH] pc_addr_plus4 = pc_out_pc_addr + 4;
  assign to_idif.pc_addr = pc_out_pc_addr;

  pc_reg pc(
    // .stall(stall),
    .clk(clk),
    .rst(rst),

    .next_pc(mux2_out_next_pc),

    .pc_addr(pc_out_pc_addr)
    );

  mux #(`COMMON_LENGTH) jump_plus4(
    .in1(jump_pc),
    .in2(pc_addr_plus4),
    .condition(jump_ce),
    .out(mux1_out_next_pc)
    );


  mux #(`COMMON_LENGTH) stall_addr_next_addr(
    .in1(pc_out_pc_addr),
    .in2(mux1_out_next_pc),
    .condition(stall),
    .out(mux2_out_next_pc)
    );

  inst_rom rom(
    .rst(rst),
    .addr(pc_out_pc_addr),
    .inst(to_idif.inst)
    );

endmodule : pif
