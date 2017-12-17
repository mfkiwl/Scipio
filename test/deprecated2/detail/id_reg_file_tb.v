`include "define.h"

module id_reg_file_tb;
  reg rst;
  reg clk;

  reg  [`REG_NUM]      rs1;
  wire [`COMMON_WIDTH] src1;
  wire                 modi1;

  reg  [`REG_NUM]       rd;

  reg [`REG_NUM]      reg_write;
  reg [`COMMON_WIDTH] data_write;

  id_reg_file DUT(
    .rst(rst),
    .clk(clk),

    .rs1(rs1),
    .src1(src1),   // output
    .modi1(modi1), // output

    .rd(rd),

    .reg_write(reg_write),
    .data_write(data_write)
    );

  task init;
    begin
    rst = 1'b1;
    repeat(4) #30 clk = ~clk;
    rst = 1'b0;
    end
  endtask

  // clock
  initial begin
    clk = 1'b0;
    init;
    forever #30 clk = ~clk;
  end

  task sync_assign_reg_data_write;
    input [`REG_NUM]      rd;
    input [`COMMON_WIDTH] data;
    begin
      reg_write  <= rd;
      data_write <= data;
    end
  endtask

  task print_nontrivial_regs;
    integer j;
    begin
      for (i = 1; i < 32; i = i + 1) begin
        if (DUT.regs[i] !== 0 || DUT.modified[i] != 0)
          $display("reg[%d]=%d, modified[%d]=%d",
                   i, DUT.regs[i], i, DUT.modified[i]);
      end
    end
  endtask

  integer i;
  task test_wb;
    begin
      $display("subtest: wb");
      init;
      for (i = 1; i < 32; ++i) begin
        @(negedge clk);
        sync_assign_reg_data_write(i, i);
      end
      @(posedge clk);
      for (i = 1; i < 32; ++i) begin
        if (i !== DUT.regs[i])
          $display("reg[%d] != %d", i, DUT.regs[i]);
      end
      $display("subfinish: wb");
    end
  endtask

  task test_modified;
    begin
      $display("subtest: modified");
      init;
      for (i = 1; i < 32; i = i + 1) begin
        @(posedge clk);
        rd = i;
      end
      @(posedge clk);
      rd = 0;
      for (i = 1; i < 32; i = i + 1) begin
        if (1 !== DUT.modified[i])
          $display("modified[%d] = %d !== 1(ans)", i, DUT.modified[i]);
      end
      for (i = 1; i < 32; i = i + 1) begin
        @(negedge clk);
        sync_assign_reg_data_write(i, i);
      end
      @(negedge clk);
      for (i = 1; i < 32; i = i + 1) begin
        if (0 !== DUT.modified[i])
          $display("modified[%d] = %d !== 0(ans)", i, DUT.modified[i]);
      end
      $display("subfinish: modified");
    end
  endtask

  initial begin
    $display("test: reg_file");
    test_wb;
    test_modified;
    $display("finish: reg_file");
    $finish;
  end

endmodule // id_reg_file_tb
