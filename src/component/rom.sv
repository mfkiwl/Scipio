`include "common_def.h"

interface rom_inf;
  bit en;
  bit done;
  bit [2:0] byte_num;

  bit [`COMMON_WIDTH] addr;
  bit [`COMMON_WIDTH] data;

  modport unit_read (output addr, byte_num, en,
                     input data, done);
  modport rom_read  (input  addr,byte_num, en,
                     output data, done);

  modport unit_write (output addr, data, byte_num, en,
                      input done);
  modport rom_write  (input addr, data, byte_num, en,
                      output done);
endinterface


module rom (
  input rst,
  input clk,

  rom_inf.rom_read  read,
  rom_inf.rom_write write
  );

  /* It is required that read.en & write.en = 0
   * at any posedge of clk.
   */

  // Since this is a fake memory,
  // "done" is always 1
  reg done;
  assign read.done  = done;
  assign write.done = done;

  // read
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else if (read.en) begin
      read.done <= 1;
      read.data <= 0;
      read.data[7:0] <= memory[read.addr >> 2];
      if (read.byte_num > 1)
        read.data[15:8] <= memory[read.addr >> 2 + 1];
      if (read.byte_num > 2)
        read.data[23:16] <= memory[read.addr >> 2 + 2];
      if (read.byte_num > 3)
        read.data[31:24] <= memory[read.addr >> 2 + 3];
    end
  end

  // write
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else if (write.en) begin
      write.done <= 1;
      memory[write.addr >> 2] <= write.data[7:0];
      if (write.byte_num > 1)
        memory[write.addr >> 2 + 1] <= write.data[15:8];
      if (write.byte_num > 2)
        memory[write.addr >> 2 + 2] <= write.data[23:16];
      if (write.byte_num > 3)
        memory[write.addr >> 2 + 3] <= write.data[31:24];
    end
  end

  // fake memory
  reg [7:0] memory [0:127];

  task reset;
    integer i;
    begin
      for (i = 0; i < 128; i = i + 1)
       memory[i] <= 0;
    end
  endtask

endmodule : rom
