`include "common_def.h"

interface jump_stall;
  bit stall;
  bit reset;

  modport pif  (input stall);
  modport ifid (input stall);
  modport id   (output stall, input reset);
  modport wb   (output reset);
endinterface
