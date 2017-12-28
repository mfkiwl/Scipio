module mux #(parameter DATA_WIDTH = 1) (
  input [DATA_WIDTH-1:0] in1,
  input [DATA_WIDTH-1:0] in2,
  input                  condition,

  output [DATA_WIDTH-1:0] out
  );

  assign out = (condition) ? in1 : in2;
endmodule : mux
