interface fifo_inf #(parameter DATA_WIDTH = 8);
  bit en;
  bit [DATA_WIDTH-1:0] data;
  bit avail;
    // pop:  avail <=> !empty
    // push: avail <=> !full

  modport unit_push (output en, data, input  avail);
  modport fifo_push (input  en, data, output avail);
  modport unit_pop  (output en, input  data, avail);
  modport fifo_pop  (input  en, output data, avail);
endinterface

module fifo #(
  parameter SIZE_WIDTH = 3,
  parameter DATA_WIDTH = 8
  )(
  input clk,
  input rst,

  fifo_inf.push push,
  fifo_inf.pop  pop
  );

  localparam SIZE = 1 << SIZE_WIDTH;

  ////////////////////////////////////
  reg [WIDTH-1:0] storage[SIZE-1:0];
  reg [SIZE_WIDTH-1:0] head, tail;

  wire to_push = push.avail && push.en;
  wire to_pop  = pop.avail  && pop.en;
  ////////////////////////////////////
  assign push.avail = (tail !== head - 1);
  assign pop.avail  = (tail !== head);

  always @ (negedge clk or posedge rst) begin
    if (rst) begin
      reset;
    end else begin
      if (to_push && to_pop) begin
        storage[tail] <= push.data;
        head <= head + 1;
        tail <= tail + 1;
      end else if (to_pop) begin
        pop.data <= storage[head];
        head <= head + 1;
      end else if (to_push) begin
        storage[tail] <= push.data;
        tail <= tail + 1;
      end
    end
  end

  task reset;
    begin
      head <= 0;
      tail <= 0;
    end
  endtask

endmodule : fifo
