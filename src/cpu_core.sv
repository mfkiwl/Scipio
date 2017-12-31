`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst
  );

  // test
  reg jump_ce;
  reg [`INST_TAG_WIDTH] target;
  always @ (posedge rst) begin
    jump_ce = 0;
    target = 0;
  end
  always @ (posedge clk) begin
    target <= target + 1;
  end
  rob_inf rob_info();
  rob_inf bc();
  rob_inf wb();
  //////////////////////

  ifid_inf if_ifid();
  wire id_out_stall;

  pif IF (
    .clk(clk),
    .rst(rst),
    .jump_ce(jump_ce),
    .stall(id_out_stall),

    .to_idif(if_ifid)
    );

  ifid_inf ifid_id();

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .stall(id_out_stall),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

  id_inf id_idex();

  rob_inf id_rob();

  id ID(
    .clk(clk),
    .rst(rst),

    .from_ifid(ifid_id),

    .stall_if(id_out_stall),

    .id_rob(id_rob),

    .to_idex(id_idex)
    );

  ex_in_inf idex_ex();

  idex IDEX(
    .rst(rst),
    .clk(clk),
    .from_id(id_idex),
    .to_ex(idex_ex)
    );

  ex_alu_out_inf ex_exwb_alu();

  ex EX(
    .rst(rst),
    .clk(clk),

    .in(idex_ex),
    .rob_info(rob_info),
    .alu_out(ex_exwb_alu)
    );

  rob ROB (
    .clk(clk),
    .rst(rst),

    .alu_in(ex_exwb_alu),

    .rob_id(id_rob),
    .broadcast(bc),
    .to_wb(wb)
    );

endmodule : cpu_core
