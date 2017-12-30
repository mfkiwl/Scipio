`include "common_def.h"

interface rob_inf;
  bit valid [0:`ROB_ENTRY_NUM-1];
  bit ready [0:`ROB_ENTRY_NUM-1];
  bit [`COMMON_WIDTH] val [0:`ROB_ENTRY_NUM-1];
  bit [`INST_TAG_WIDTH] tag [0:`ROB_ENTRY_NUM-1];

  modport snoop (input valid, ready, val, tag);
endinterface
