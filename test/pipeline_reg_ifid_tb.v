module pipeline_reg_ifid_tb;
  reg clk;
  reg rst;

  // clock
  initial begin
    clk = 1'b0;
    rst = 1'b1;
    repeat(4) #10 clk = ~clk;
    rst = 1'b0;
    forever #10 clk = ~clk;
  end

  reg  [31:0] inst_in;
  wire [31:0] inst_out;
  reg  [31:0] result;


  pipeline_reg_ifid DUT(
    .rst(rst),

    .inst_in(inst_in),
    .inst_out(inst_out)
    );

  initial begin
    @(negedge rst);
    $display("test: pipeline_reg_ifid");
    @(posedge clk);
    inst_in = $urandom;
    repeat (10) begin
      @(posedge clk);
      result = inst_out;
      #1;
      $display("reslut = %d", result);
      #1;
      inst_in = $urandom;
      $display("in = %d", inst_in);
    end
    $display("finish: pipeline_reg_ifid");
    $finish;
  end


endmodule // pipeline_reg_ifid_tb
