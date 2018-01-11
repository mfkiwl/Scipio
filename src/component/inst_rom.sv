`include "common_def.h"

module inst_rom (
  input rst,
  input ce,
  input [`COMMON_WIDTH] addr,

  output reg [`COMMON_WIDTH] inst
  );

  reg [`COMMON_WIDTH] inst_mem[127:0];


  integer i;
  initial begin
    for (i = 0; i < 127; i = i + 1) begin
      inst_mem[i] = 0;
    end
    $readmemh("/home/aaronren/Desktop/test/jumps.data", inst_mem);
    for (i = 0; i < 128; i = i + 1) begin
      inst_mem[i][31:24] <= inst_mem[i][7:0];
      inst_mem[i][23:16] <= inst_mem[i][15:8];
      inst_mem[i][15:8]  <= inst_mem[i][23:16];
      inst_mem[i][7:0]   <= inst_mem[i][31:24];
    end
  end
  // always @ (posedge rst) begin
  //   inst_mem[0] <= 32'h34011100;
  //   // inst_mem[1] <= 32'h34020020;
  //   inst_mem[1] <= 32'b1101111; // JAL
  //   inst_mem[2] <= 32'h3403ff00;
  //   inst_mem[3] <= 32'h3404ffff;
  // end

  always @( * ) begin
    if (!rst)
      inst <= inst_mem[addr / 4];
  end

endmodule : inst_rom
