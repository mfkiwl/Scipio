`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst
  );

  // test
  reg jump_ce;
  always @ (posedge rst) begin
    jump_ce = 0;
  end

  ifid_inf if_ifid();

  pif IF (
    .clk(clk),
    .rst(rst),
    .jump_ce(jump_ce),

    .to_idif(if_ifid)
    );

  ifid_inf ifid_id();

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

endmodule : cpu_core
