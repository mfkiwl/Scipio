`include "common_def.h"

module cpu_core (
  input wire clk,
  input wire rst
  );

  ifid_inf if_ifid();
  ifid_inf ifid_id();

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

endmodule : cpu_core
