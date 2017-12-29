`include "common_def.h"

module reservation_station (
  input clk,
  input rst,
  input busy,

  // inst in
  input       push_ce,
  idex_inf.in entry, // without ex_unit

  output reg full,

  // to calcuating unit
  output reg [`INST_OP_WIDTH] op,
  output reg [`COMMON_WIDTH]  val [1:2],
  // to control unit
  output reg [`INST_TAG_WIDTH] target // pos in ROB
  );

  ReservEntry insts [0:`RES_ENTRY_NUM-1];

  task reset;
    integer i;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        insts[i].valid <= 0;
    end
  endtask

  task check_full;
    integer cf_i;
    begin
      for (cf_i = 0; cf_i < `RES_ENTRY_NUM; cf_i = cf_i + 1)
        full = full & (~insts[cf_i].valid);
    end
  endtask

  task push;
    integer i;
    integer pos;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        pos = (insts[i].valid) ? pos : i;
      insts[pos].valid = 1;
      insts[pos].op    = entry.op;
      insts[pos].tag   = entry.tag;
      insts[pos].val   = entry.val;
      // addr
      insts[pos].target = entry.target;
    end
  endtask

  task issue;
    integer i, pos;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        if (insts[i].valid &&
            insts[i].tag[1] == `TAG_INVALID &&
            insts[i].tag[2] == `TAG_INVALID)
            pos = i;
      op = insts[pos].op;
      val = insts[pos].val;
      target = insts[pos].target;
    end
  endtask

  integer p_i;
  always @ ( * ) begin
    if (rst)
      reset;
    else begin
      if (push_ce)
        push;
      if (!busy)
        issue;
    end
  end
endmodule : reservation_station
