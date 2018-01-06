`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst
  );


  // rob_inf rob_info();
  // rob_inf bc();
  // rob_inf wb();
  //////////////////////

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

  pif IF (
    .clk(clk),
    .rst(rst),

    .jump_stall(jump_stall),
    .full_stall(full_stall),

    .to_idif(if_ifid)
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
    .mem_out(ex_exwb_mem)
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
    .mem_out(exwb_wb_mem)
    );

  rob ROB (
    .clk(clk),
    .rst(rst),

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
