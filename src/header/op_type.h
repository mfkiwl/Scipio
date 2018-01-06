`define OP_TYPE_WIDTH 7:0

`define OP_NOP		0
`define OP_ADD		1
`define OP_ADDU	  2
`define OP_SUB		3
`define OP_SUBU	  4
// `define OP_MULTL	5
// `define OP_MULTH	6
// `define OP_MULTLU	7
// `define OP_MULTHU	8
// `define OP_DIV		9
// `define OP_MOD		10
// `define OP_DIVU	11
// `define OP_MODU	12
`define OP_AND		13
`define OP_OR		  14
`define OP_NOR		15
`define OP_XOR		16
`define OP_SLL		17
`define OP_SRL		18
`define OP_SRA		19
`define OP_ROR		20
`define OP_SEQ		21
`define OP_SLT		22
`define OP_SLTU	  23

`define OP_JAL    24
`define OP_JALR   25

`define OP_BEQ    26
`define OP_BNE    27
`define OP_BLT    28
`define OP_BGE    29
`define OP_BLTU   30
`define OP_BGEU   31

`define OP_STORE  32
`define OP_LOAD   33
`define OP_LOADU  34
