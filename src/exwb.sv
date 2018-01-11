`timescale 1ns/1ps
`include "common_def.h"

interface driver;
  bit ce;
  bit en;

  modport driving (output ce, en);
  modport drived  (input  ce, en);
endinterface

module exwb (
  input clk,
  input rst,

  driver.driving driving,

  ex_exwb_alu_inf.exwb        alu_in,
  ex_exwb_forwarder_inf.exwb  forwarder_in,
  ex_exwb_jump_inf.exwb       jump_in,
  ex_exwb_branch_inf.exwb     branch_in,
  ex_exwb_mem_inf.exwb        mem_in,

  exwb_rob_tar_res_inf.exwb alu_out,
  exwb_rob_tar_res_inf.exwb forwarder_out,
  exwb_rob_jump_inf.exwb    jump_out,
  exwb_rob_branch_inf.exwb  branch_out,
  exwb_rob_tar_res_inf.exwb mem_out
  );

  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      driving.en = -1;
    end else begin
      driving.en = 1;
      forward_alu;
      forward_forwarder;
      forward_jump;
      forward_branch;
      forward_mem;
      driving.ce = ~driving.ce;
    end
  end

  // alu
  task forward_alu;
    begin
      if (rst) begin
        alu_out.target = `TAG_INVALID;
      end else begin
        alu_out.result = alu_in.result;
        alu_out.target = alu_in.target;
      end
    end
  endtask

  // forwarder
  task forward_forwarder;
    begin
      if (rst) begin
        forwarder_out.target = `TAG_INVALID;
      end else begin
        forwarder_out.result = forwarder_in.result;
        forwarder_out.target = forwarder_in.target;
      end
    end
  endtask

  // jump
  task forward_jump;
    begin
      if (rst) begin
        jump_out.target = `TAG_INVALID;
      end else begin
        jump_out.target = jump_in.target;
        jump_out.ori_pc = jump_in.ori_pc;
        jump_out.next_pc = jump_in.next_pc;
      end
    end
  endtask

  // branch
  task forward_branch;
    begin
      if (rst) begin
        branch_out.target = `TAG_INVALID;
      end else begin
        branch_out.target = branch_in.target;
        branch_out.next_pc = branch_in.next_pc;
        branch_out.cmp_res = branch_in.cmp_res;
      end
    end
  endtask

  // mem
  task forward_mem;
    begin
      if (rst) begin
        mem_out.target = `TAG_INVALID;
      end else begin
        mem_out.result = mem_in.result;
        mem_out.target = mem_in.target;
      end
    end
  endtask

endmodule : exwb
