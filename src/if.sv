`timescale 1ns/1ps

`include "common_def.h"

interface pif_ifid_inf;
  bit [`COMMON_WIDTH] inst;
  bit [`COMMON_WIDTH] pc_addr;

  modport pif (output inst, pc_addr);
  modport ifid (input inst, pc_addr);
endinterface

interface if_icache_inf;
  bit read_flag;
  bit [31:0] addr;
  bit [31:0] read_data;
  bit busy;
  bit done;

  modport pif (output read_flag, addr,
               input  read_data, busy, done);
endinterface

module pif (
  input clk,
  input rst,

  jump_stall_inf.pif jump_stall,
  full_stall_inf.pif full_stall,

  pif_ifid_inf.pif to_idif,

  if_icache_inf.pif    with_icache
  );


  wire [`COMMON_WIDTH] pc_out_pc_addr;
  reg  [`COMMON_WIDTH] next_pc;

  wire stall = jump_stall.stall || full_stall.stall || with_icache.busy;
  assign next_pc = (jump_stall.jump_en) ? jump_stall.jump_addr : pc_out_pc_addr + 4;

  always @ ( * ) begin
    to_idif.inst = 0;
    with_icache.read_flag = 0;
    if (rst) begin
      to_idif.inst = 0;
      with_icache.read_flag = 0;
    end else if (with_icache.done) begin
      to_idif.inst = with_icache.read_data;
      to_idif.pc_addr = pc_out_pc_addr;
    end else if (!with_icache.busy) begin
      with_icache.read_flag = 1;
      with_icache.addr = pc_out_pc_addr;
    end else if (with_icache.busy) begin
      with_icache.read_flag = 0;
    end
  end

  pc_reg pc (
    .clk(clk),
    .rst(rst),

    .stall(stall),

    .next_pc(next_pc),

    .pc_addr(pc_out_pc_addr)
    );

  // always @ (posedge rst) begin
  //   with_icache.read_flag = 0;
  // end
  //
  // always @ ( * ) begin
  //   with_icache.addr      = pc_out_pc_addr;
  //   with_icache.read_flag = !stall;
  //   to_idif.inst = (with_icache.done) ? with_icache.read_data : 0;
  //   to_idif.pc_addr       = pc_out_pc_addr;
  // end



  // inst_rom rom(
  //   .rst(rst),
  //   .addr(pc_out_pc_addr),
  //
  //   .inst(to_idif.inst)
  //   );

endmodule : pif
