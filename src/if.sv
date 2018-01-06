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

  jump_stall_inf.pif jump_stall,
  full_stall_inf.pif full_stall,

  pif_ifid_inf.pif to_idif
  );

  wire [`COMMON_WIDTH] pc_out_pc_addr;
  reg  [`COMMON_WIDTH] next_pc;

  assign to_idif.pc_addr = pc_out_pc_addr;

  wire stall = jump_stall.stall || full_stall.stall;

  always @ ( * ) begin
    if (stall)
      next_pc = pc_out_pc_addr;
    else if (jump_stall.jump_en)
      next_pc = jump_stall.jump_addr;
    else
      next_pc = pc_out_pc_addr + 4;
  end

  pc_reg pc (
    .clk(clk),
    .rst(rst),

    .next_pc(next_pc),

    .pc_addr(pc_out_pc_addr)
    );


  inst_rom rom(
    .rst(rst),
    .addr(pc_out_pc_addr),

    .inst(to_idif.inst)
    );

endmodule : pif
