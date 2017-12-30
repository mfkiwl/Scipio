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

  idex_inf id_idex();

  id ID(
    .clk(clk),
    .rst(rst),

    .from_ifid(ifid_id),

    .stall_if(id_out_stall),

    .target(target), // test

    .to_idex(id_idex)
    );

endmodule : cpu_core
