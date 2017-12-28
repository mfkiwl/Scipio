`include "common_def.h"

struct {
  bit [`INST_OP_WIDTH]  op;
  bit [`INST_TAG_WIDTH] tag [1:0];
  bit [`COMMON_WIDTH]   val [1:0];
  bit [`RES_ADDR_WIDTH] addr;
  bit [`INST_TAG_WIDTH] target; // the position in ROB
} ReservEntry;
