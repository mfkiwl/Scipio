`include "common_def.h"

module exwb (
  input clk,
  input rst,

  ex_exwb_alu_inf.exwb        alu_in,
  ex_exwb_forwarder_inf.exwb forwarder_in,

  exwb_rob_tar_res_inf.exwb alu_out,
  exwb_rob_tar_res_inf.exwb forwarder_out
  );

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      alu_out.target <= `TAG_INVALID;
    end else begin
      alu_out.result <= alu_in.result;
      alu_out.target <= alu_in.target;
    end
  end

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      forwarder_out.target <= `TAG_INVALID;
    end else begin
      forwarder_out.result <= forwarder_in.result;
      forwarder_out.target <= forwarder_in.target;
    end
  end

endmodule : exwb
