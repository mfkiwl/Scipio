`include "common_def.h"

module alu_tb;
  wire [`COMMON_WIDTH] result;
  reg clk;

  alu_reserv_inf entry();
  rob_inf rob_info();

  alu DUT(
    .clk(clk),
    .new_entry(entry),
    .rob_info(rob_info),
    .result(result)
    );

  integer i;
  task add_entry;
    for (i = 0; i < 8; i = i + 1) begin
      DUT.entries[i].valid = 1;
      DUT.entries[i].val[1] = 1;
      DUT.entries[i].val[2] = 2;
      DUT.entries[i].op = `ALU_ADD;
    end
  endtask

  always @ ( * ) begin
    $display("%d", result);
  end

  initial begin
    clk = 0;
    DUT.test_add;
  end



endmodule : alu_tb
