module pipeline_reg_ifid (
  input rst,

  input  [31:0] inst_in,

  output reg [31:0] inst_out
  );

  always @ ( * )
    inst_out <= inst_in;

  always @ (posedge rst) begin
    inst_out <= 32'b0;
  end

endmodule // pipeline_reg_ifid
