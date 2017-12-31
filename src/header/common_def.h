`include "alu_type.h"
`include "inst_code.h"
`include "op_type.h"

`define TODO_WIDTH   31:0

`define COMMON_WIDTH  31:0
`define COMMON_LENGTH 32
`define REG_NUM_WIDTH 4:0
`define REG_NUM       32

`define EX_UNIT_NUM_WIDTH 2:0
`define EX_UNIT_NUM       8
`define EX_ERR_UNIT       3'd0
`define EX_ALU_UNIT       3'd1
`define EX_FORWARDER_UNIT 3'd2
`define EX_MEM_UNIT       3'd3

`define INST_OP_WIDTH   5:0
`define INST_TAG_WIDTH  3:0
`define TAG_INVALID     4'b1111
`define RES_ADDR_WIDTH  31:0


`define ROB_ENTRY_NUM   8
`define ROB_ENTRY_NUM_WIDTH 2:0
`define RES_ENTRY_NUM   8
`define RES_ENTRY_NUM_WIDTH 2:0
