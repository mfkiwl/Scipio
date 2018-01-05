`include "common_def.h"

module exwb (
  input clk,
  input rst,

  ex_exwb_alu_inf.exwb        alu_in,
  ex_exwb_forwarder_inf.exwb  forwarder_in,
  ex_exwb_jump_inf.exwb       jump_in,

  exwb_rob_tar_res_inf.exwb alu_out,
  exwb_rob_tar_res_inf.exwb forwarder_out,
  exwb_rob_jump_inf.exwb    jump_out
  );

  // alu
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      alu_out.target <= `TAG_INVALID;
    end else begin
      alu_out.result <= alu_in.result;
      alu_out.target <= alu_in.target;
    end
  end

  // forwarder
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      forwarder_out.target <= `TAG_INVALID;
    end else begin
      forwarder_out.result <= forwarder_in.result;
      forwarder_out.target <= forwarder_in.target;
    end
  end

  // jump
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      jump_out.target <= `TAG_INVALID;
    end else begin
      jump_out.target <= jump_in.target;
      jump_out.ori_pc <= jump_in.ori_pc;
      jump_out.next_pc <= jump_in.next_pc;
    end
  end

endmodule : exwb
