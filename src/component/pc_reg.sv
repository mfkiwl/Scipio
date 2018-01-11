`timescale 1ns/1ps

`include "common_def.h"

module pc_reg (
  input clk,
  input rst,

  input stall,
  input jump,

  input [`COMMON_WIDTH] next_pc,

  output reg [`COMMON_WIDTH] pc_addr
  );

  reg [`COMMON_WIDTH] pc;
  always @ ( * ) pc = next_pc;

  always @ (posedge clk or posedge rst) begin
      if (rst) begin
        pc_addr <= -4;
        // pc_addr <= 32'h4;
        pc <= 0;
      end else begin
        pc_addr <= pc;
    end
  end


  // reg [`COMMON_WIDTH] pc;
  //
  // always @ (posedge clk or posedge rst) begin
  //   if (rst) begin
  //     pc <= 0;
  //     pc_addr <= 0;
  //   end else if (jump) begin
  //     pc_addr <= next_pc;
  //     pc      <= next_pc + 4;
  //   end else if (!stall) begin
  //     pc_addr <= pc;
  //     pc <= next_pc;
  //   end
  // end


endmodule : pc_reg
