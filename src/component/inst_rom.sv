`include "common_def.h"

module inst_rom (
  input rst,
  input ce,
  input [`COMMON_WIDTH] addr,

  output reg [`COMMON_WIDTH] inst
  );

  reg [`COMMON_WIDTH] inst_mem[0:31];


  // $readmemh("/home/aaronren/Desktop/inst_rom.data", inst_mem);
  always @ (posedge rst) begin
    inst_mem[0] <= 32'h34011100;
    inst_mem[1] <= 32'h34020020;
    inst_mem[2] <= 32'h3403ff00;
    inst_mem[3] <= 32'h3404ffff;
  end

  always @( * ) begin
    if (!rst)
      inst <= inst_mem[addr / 4];
  end

endmodule : inst_rom
