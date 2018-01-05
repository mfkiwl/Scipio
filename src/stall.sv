`include "common_def.h"

interface jump_stall_inf;
  bit stall;
  bit reset;

  bit jump_en;
  bit [`COMMON_WIDTH] jump_addr;

  /* At ID, if a inst which may result to a jump is
   * detected. ID will set "stall" to 1 (posedge).
   * Otherwise, "stall" = 0.
   *
   * At IF, if "stall" 0 -> 1, which means ID just
   * detected a (possible) jump, IF should reset the
   * next pc addr to the current pc addr. So that in
   * the next period, IF will still fetch out the
   * current inst.
   *
   * At IFID, if "stall" = 1, IFID should not
   * forward the real data from IF to ID. A NOP will be
   * sent instead.
   *
   * At WB (negedge), if the inst committed is a JUMP,
   * it should sent a reseting signal to ID, so that
   * ID will set the "stall" of IF and IFID to 0.
   *
   * Caution:
   * When the stall is reset to 0, the data in IFID
   * is still out of date. So, another NOP is needed.
   */
  modport pif  (input stall,
                input jump_en, jump_addr);
  modport ifid (input stall);
  modport id   (output stall, input reset);
  modport wb   (output reset,
                output jump_en, jump_addr);
endinterface
