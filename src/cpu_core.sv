`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst
  );

  // test
  reg jump_ce;
  reg stall;
  always @ (posedge rst) begin
    jump_ce = 0;
    stall = 0;
  end

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
    // EXWB_WB
      exwb_rob_tar_res_inf exwb_wb_alu();
      exwb_rob_tar_res_inf exwb_wb_forwarder();


    wb_id_inf   wb_id();
  // boradcast & snoop
    rob_broadcast_inf rob_broadcast();
  // tag
    rob_pos_inf rob_pos();
  ////////////////////////////////

  pif IF (
    .clk(clk),
    .rst(rst),
    .jump_ce(jump_ce),
    .stall(stall),

    .to_idif(if_ifid)
    );

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .stall(stall),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

  id ID(
    .clk(clk),
    .rst(rst),

    .from_ifid(ifid_id),

    .stall_if(id_out_stall),

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
    .alu_out(ex_exwb_alu),
    .forwarder_out(ex_exwb_forwarder)
    );

  exwb EXWB(
    .clk(clk),
    .rst(rst),

    .alu_in(ex_exwb_alu),
    .alu_out(exwb_wb_alu),

    .forwarder_in(ex_exwb_forwarder),
    .forwarder_out(exwb_wb_forwarder)
    );

  rob ROB (
    .clk(clk),
    .rst(rst),

    .alu_in(exwb_wb_alu),
    .forwarder_in(exwb_wb_forwarder),

    .broadcast(rob_broadcast),
    .pos(rob_pos),
    .to_wb(wb_id)
    );

endmodule : cpu_core
