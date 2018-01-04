`include "common_def.h"

module exwb (
  input clk,
  input rst,

  ex_exwb_alu_inf.exwb alu_in,

  exwb_rob_alu_inf.exwb alu_out
  );

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      ;
    end else begin
      alu_out.result = alu_in.result;
      alu_out.target = alu_in.target;
    end
  end

endmodule : exwb
