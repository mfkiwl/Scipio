module uart_tb;
  reg rst;
  reg clk;
  reg Rx;
  wire Tx;
  uart_recv_inf receiver();
  uart_send_inf sender();

  localparam CLOCKRATE = 100;
  localparam BAUDRATE  = 10;
  localparam SAMPLE_INTERVAL = CLOCKRATE / BAUDRATE;

  uart_comm #(.CLOCKRATE(CLOCKRATE), .BAUDRATE(BAUDRATE)) uart (
    .clk(clk),
    .rst(rst),

    .recv(receiver),
    .send(sender),

    .Rx(Rx),
    .Tx(Tx)
    );

  // send
  initial begin
    // test_send;
    test_recv;
  end

  reg [7:0] recv_data;
  task test_recv;
    integer i, j, parity;
    reg [7:0] ans;
    begin
      @(negedge rst);
      for (i = 0; i < 2; i = i + 1) begin
        receiver.en = 0;
        recv_data = 0;
        parity = 0;
        ans = $random;
        $display("send %h", ans);
        Rx = 0;
        @(negedge clk);
        receiver.en = 1;
        repeat (SAMPLE_INTERVAL) @(posedge clk);
        for (j = 0; j < 8; j = j + 1) begin
          Rx = ans[j];
          parity = parity ^ ans[j];
          repeat (SAMPLE_INTERVAL) @(posedge clk);
        end
        Rx = parity;
        repeat (SAMPLE_INTERVAL) @(posedge clk);
        
        repeat (SAMPLE_INTERVAL) @(posedge clk);
        $display("get %h", recv_data);
      end
    end
  endtask

  always @ (negedge clk)
    if (receiver.valid)
      recv_data = receiver.data;


  // record Tx
  reg [8:0] Tx_out;
  integer cnt, flag, i, busy;
  always @(negedge Tx iff !busy) begin
    busy = 1;
    for (i = -1; i < 8; i = i + 1) begin
      cnt = 0;
      while (cnt !== SAMPLE_INTERVAL) begin
        @(posedge clk);
        cnt = cnt + 1;
        if (cnt == SAMPLE_INTERVAL / 2 && i !== -1) begin
          Tx_out[i] = Tx;
        end
      end
    end
    busy = 0;
  end

  task test_send;
    integer i;
    reg [7:0] ans;
    begin
      busy = 0;
      @(negedge rst);
      for (i = 0; i < 10; i = i + 1) begin
        sender.en = 0;
        Tx_out = 0;
        ans = $random;
        $display("send %h", ans);
        @(negedge clk);
        sender.en = 1;
        sender.data = ans;
        while (!sender.completed)
          @(negedge clk);
        if (ans !== Tx_out[7:0]) begin
          $display("(ans)%h != %h", ans, Tx_out[7:0]);
        end
        $display("get %h", Tx_out[7:0]);
      end
    end
  endtask

  // clk
  initial begin
    rst = 1;
    clk = 0;
    #10;
    rst = 0;
    #10;
    forever #20 clk = ~clk;
  end

endmodule // uart_tb
