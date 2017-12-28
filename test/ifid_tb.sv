/* CE test: x
 * RE test:
 */

module ifid_tb;
  reg clk;
  reg rst;

  initial begin
    clk = 0;
    rst = 1;
    #10;
    rst = 0;
    forever #10 clk = ~clk;
  end

  ifid_inf if_ifid();
  ifid_inf ifid_id();

  ifid IFID(
    .rst(rst),
    .clk(clk),
    .from_if(if_ifid),
    .to_id(ifid_id)
    );

  initial begin
    @(negedge rst);
    repeat(10) begin
      @(negedge clk);
      if_ifid.inst = $random;
    end
    $finish;
  end

endmodule // ifid_tb
