module reg_file (
  input rst,

  input wire [4:0]  read_num1,
  output reg [31:0] read_res1,

  input wire [4:0]  read_num2,
  output reg [31:0] read_res2,

  input wire [4:0]  write_num,
  input wire [31:0] write_res
  );

  reg [31:0] regs[31:1];

  task reset_regs;
    integer i;
    begin
      for (i = 1; i <= 31; i++) begin
        regs[i] = 32'b0;
      end
    end
  endtask

  always @ (posedge rst) reset_regs;

  always @ (read_num1)
    read_res1 <= (read_num1 == 0) ? 32'b0 : regs[read_num1];
  always @ (read_num2)
    read_res2 <= (read_num2 == 0) ? 32'b0 : regs[read_num2];
  always @ (write_num or write_res)
    regs[write_num] <= write_res;

endmodule // reg_file
