`include "common_def.h"

interface rob_inf;
  bit full;

  output [`TODO_WIDTH]  op;

  output [`REG_NUM_WIDTH] rd;

  modport id(input full, output rd);

endinterface
