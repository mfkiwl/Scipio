`define REG_WIDTH  31:0

`define POS_OPCODE 6:0
`define POS_RD     11:7
`define POS_FUNCT3 14:12
`define POS_RS1    19:15
`define POS_RS2    24:20
`define POS_FUNCT7 31:25
`define POS_IMM    31:20
// todo: S/B/U/J type


// ALU_OPCODE
`define ALU_OPCODE_WIDTH 4:0

`define ALU_NOP		0
`define ALU_ADD		1
`define ALU_ADDU	2
`define ALU_SUB		3
`define ALU_SUBU	4
// `define ALU_MULTL	5
// `define ALU_MULTH	6
// `define ALU_MULTLU	7
// `define ALU_MULTHU	8
// `define ALU_DIV		9
// `define ALU_MOD		10
// `define ALU_DIVU	11
// `define ALU_MODU	12
`define ALU_AND		13
`define ALU_OR		14
`define ALU_NOR		15
`define ALU_XOR		16
`define ALU_SLL		17
`define ALU_SRL		18
`define ALU_SRA		19
`define ALU_ROR		20
`define ALU_SEQ		21
`define ALU_SLT		22
`define ALU_SLTU	23
