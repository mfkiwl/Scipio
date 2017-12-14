module reg_file_tb ();
  reg [4:0] regnum1;
  reg [4:0] regnum2;

  wire [31:0] result1;
  wire [31:0] result2;

  reg [4:0] write_num;
  reg [31:0] write_res;

  reg rst;

  reg_file DUT(
    .rst(rst),
    .read_num1(regnum1),
    .read_res1(result1),
    .read_num2(regnum2),
    .read_res2(result2),
    .write_num(write_num),
    .write_res(write_res)
    );

  integer unsigned i;
  initial begin
    rst = 1'b1;
    rst = 1'b0;
    #5;
    $display("test: reset & read");
    for (i = 0; i <= 31; i++) begin
      regnum1 = i;
      #1;
      // $display("reseting %d", i);
      if (result1 !== 0) $display("reset %d failed", i);
    end
    $display("finish: reset & read");
    $display("test: write & read");
    for (i = 0; i <= 31; i++) begin
      {write_num, write_res} = {i, i};
      #1;
      regnum2 = i;
      #1
      // $display("reg[%d] = %d", i, result2);
      if (result2 != i)
        $display("reg[%d] != %d", i, i);
    end
    $display("finish: write & read");
    $finish;
  end

endmodule // reg_file_tb
