`timescale 1ns/1ps

`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst,

  //To Memory Controller
  output [2*2-1:0] 	rw_flag,
  output [2*32-1:0]	addr,
  input [2*32-1:0]	read_data,
  output [2*32-1:0]	write_data,
  output [2*4-1:0]	write_mask,
  input [1:0]			  busy,
  input [1:0]			  done
  );


  /////////// Interface //////////
  // pipeline
    pif_ifid_inf if_ifid();
    ifid_id_inf  ifid_id();
    id_idex_inf  id_idex();
    idex_ex_inf  idex_ex();
    // EX -> EXWB
      ex_exwb_alu_inf       ex_exwb_alu();
      ex_exwb_forwarder_inf ex_exwb_forwarder();
      ex_exwb_jump_inf      ex_exwb_jump();
      ex_exwb_branch_inf    ex_exwb_branch();
      ex_exwb_mem_inf       ex_exwb_mem();
    // EXWB_WB
      exwb_rob_tar_res_inf exwb_wb_alu();
      exwb_rob_tar_res_inf exwb_wb_forwarder();
      exwb_rob_jump_inf    exwb_wb_jump();
      exwb_rob_branch_inf  exwb_wb_branch();
      exwb_rob_tar_res_inf exwb_wb_mem();
      driver               exwb_wb_driver();

    wb_id_inf   wb_id();
  // boradcast & snoop
    rob_broadcast_inf rob_broadcast();
    rob_mem_inf       rob_head_info();
  // tag
    rob_pos_inf rob_pos();
  // stall
    jump_stall_inf jump_stall();
    full_stall_inf full_stall();
  ////////////////////////////////

  ///////////////ICACHE/////////////////
  if_icache_inf if_icache();

  wire [1:0]	ICACHE_rw_flag;
  wire [31:0]	ICACHE_addr;
  wire [31:0]	ICACHE_read_data;
  // wire [31:0]	ICACHE_write_data;
  // wire [3:0]	ICACHE_write_mask;
  wire		ICACHE_busy;
  wire 		ICACHE_done;

  // wire		ICACHE_flush_flag;
  // wire [31:0]	ICACHE_flush_addr;

  // assign ICACHE_write_data = 0;
  // assign ICACHE_write_mask = 0;
  assign ICACHE_rw_flag[1] = 0;
  assign ICACHE_addr = if_icache.addr;
  assign ICACHE_rw_flag[0] = if_icache.read_flag;
  assign if_icache.read_data = ICACHE_read_data;
  assign if_icache.busy = ICACHE_busy;
  assign if_icache.done = ICACHE_done;

  cache ICACHE(
    .CLK(clk), .RST(rst),
    .rw_flag_(ICACHE_rw_flag),
    .addr_(ICACHE_addr),
    .read_data(ICACHE_read_data),
    // ICACHE_write_data, ICACHE_write_mask,
    .write_data_(32'b0), .write_mask_(4'b0),
    .busy(ICACHE_busy), .done(ICACHE_done),
    // ICACHE_flush_flag, ICACHE_flush_addr,
    .flush_flag(1'b0), .flush_addr(0),

    .mem_rw_flag(rw_flag[3:2]),
    .mem_addr(addr[63:32]),
    .mem_read_data(read_data[63:32]),
    .mem_write_data(write_data[63:32]),
    .mem_write_mask(write_mask[7:4]),
    .mem_busy(busy[1]),
    .mem_done(done[1]));
  //////////////////////////////////////
  //////////////DCACHE//////////////////
  mem_dcache_inf mem_dcache();

  wire [1:0]	DCACHE_rw_flag;
  wire [31:0]	DCACHE_addr;
  wire [31:0]	DCACHE_read_data;
  wire [31:0]	DCACHE_write_data;
  wire [3:0]	DCACHE_write_mask;
  wire		DCACHE_busy;
  wire 		DCACHE_done;

  // assign ICACHE_flush_flag = DCACHE_rw_flag[1];
  // assign ICACHE_flush_addr = DCACHE_addr;
  assign DCACHE_rw_flag = mem_dcache.rw_flag;
  assign DCACHE_addr    = mem_dcache.addr;
  assign DCACHE_write_data = mem_dcache.write_data;
  assign DCACHE_write_mask = mem_dcache.write_mask;
  assign mem_dcache.read_data = DCACHE_read_data;
  assign mem_dcache.busy = DCACHE_busy;
  assign mem_dcache.done = DCACHE_done;

  cache DCACHE(
    clk, rst,
    DCACHE_rw_flag,
    DCACHE_addr,
    DCACHE_read_data,
    DCACHE_write_data, DCACHE_write_mask,
    DCACHE_busy, DCACHE_done,
    1'b0, 32'b0,
    rw_flag[1:0], addr[31:0], read_data[31:0],
    write_data[31:0], write_mask[3:0], busy[0], done[0]);
  //////////////////////////////////////

  pif IF (
    .clk(clk),
    .rst(rst),

    .jump_stall(jump_stall),
    .full_stall(full_stall),

    .to_idif(if_ifid),
    .with_icache(if_icache)
    );

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .jump_stall(jump_stall),
    .full_stall(full_stall),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

  id ID(
    .clk(clk),
    .rst(rst),

    .from_ifid(ifid_id),

    .jump_stall(jump_stall),
    .full_stall(full_stall),

    .rob_pos(rob_pos),
    .wb(wb_id),
    .to_idex(id_idex)
    );

  idex IDEX(
    .rst(rst),
    .clk(clk),
    .from_id(id_idex),
    .to_ex(idex_ex)
    );

  ex EX(
    .rst(rst),
    .clk(clk),

    .in(idex_ex),
    .rob_info(rob_broadcast),
    .rob_head_info(rob_head_info),

    .alu_out(ex_exwb_alu),
    .forwarder_out(ex_exwb_forwarder),
    .jump_out(ex_exwb_jump),
    .branch_out(ex_exwb_branch),
    .mem_out(ex_exwb_mem),

    .with_dcache(mem_dcache)
    );

  exwb EXWB(
    .clk(clk),
    .rst(rst),

    .alu_in(ex_exwb_alu),
    .alu_out(exwb_wb_alu),

    .forwarder_in(ex_exwb_forwarder),
    .forwarder_out(exwb_wb_forwarder),

    .jump_in(ex_exwb_jump),
    .jump_out(exwb_wb_jump),

    .branch_in(ex_exwb_branch),
    .branch_out(exwb_wb_branch),

    .mem_in(ex_exwb_mem),
    .mem_out(exwb_wb_mem),

    .driving(exwb_wb_driver)
    );

  rob ROB (
    .clk(clk),
    .rst(rst),

    .drived(exwb_wb_driver),

    .alu_in(exwb_wb_alu),
    .forwarder_in(exwb_wb_forwarder),
    .jump_in(exwb_wb_jump),
    .branch_in(exwb_wb_branch),
    .mem_in(exwb_wb_mem),

    .broadcast(rob_broadcast),
    .pos(rob_pos),
    .to_wb(wb_id),
    .to_mem(rob_head_info),

    .jump_stall(jump_stall)
    );

endmodule : cpu_core
