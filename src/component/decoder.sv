`include "common_def.h"

module decoder (
  input rst,

  input [`COMMON_WIDTH] inst,
  input [`COMMON_WIDTH] pc_addr,

  output reg [`EX_UNIT_NUM_WIDTH] ex_unit,

  output reg [`OP_TYPE_WIDTH] op,
  output reg [`COMMON_WIDTH]  imm,
    // choose between imm and src2
  output reg                  imm_tag,
    // choose between pc_addr and src1
  output reg                  pc_tag,
    // whether the pc_addr should be stored in rd
  output reg                  store_pc_tag,
    // whether IF should stop
    // TODO
  output reg                  stall,
    // whether MEM_LOAD
  output reg                  load_tag,

  // to reg_file
  output reg                  ce [1:2],
  output reg [`REG_NUM_WIDTH] rs [1:2],
  output reg                  rd_ce,
  output reg [`REG_NUM_WIDTH] rd
  );

  function [9:0] merge_funct73;
    input  [6:0] funct7;
    input  [2:0] funct3;
    begin
      merge_funct73 = {funct7, funct3};
    end
  endfunction

  task reset;
    begin
      rd <= 0;
      ce[1] <= 0;
      ce[2] <= 0;
      ex_unit <= 0;
      imm_tag <= 0;
      pc_tag <= 0;
      store_pc_tag <= 0;
      stall <= 0;
      load_tag <= 0;
    end
  endtask

  task decode_rtype;
    begin
      ex_unit <= `EX_ALU_UNIT;
      // imm
      imm_tag <= 0;
      pc_tag <= 0;
      store_pc_tag <= 0;
      ce[1] <= 1;
      rs[1] <= inst[`POS_RS1];
      ce[2] <= 1;
      rs[2] <= inst[`POS_RS2];
      rd_ce <= 1;
      rd <= inst[`POS_RD];
      case (merge_funct73(inst[`POS_FUNCT7], inst[`POS_FUNCT3]))
        `ADD_FUNCT73:  op <= `ALU_ADD;
        `SUB_FUNCT73:  op <= `ALU_SUB;
        `SLL_FUNCT73:  op <= `ALU_SLL;
        `SLT_FUNCT73:  op <= `ALU_SLT;
        `SLTU_FUNCT73: op <= `ALU_SLTU;
        `XOR_FUNCT73:  op <= `ALU_XOR;
        `SRL_FUNCT73:  op <= `ALU_SRL;
        `SRA_FUNCT73:  op <= `ALU_SRA;
        `OR_FUNCT73:   op <= `ALU_OR;
        `AND_FUNCT73:  op <= `ALU_AND;
        default: op <= `ALU_NOP;
      endcase
    end
  endtask

  task decode_itype;
    begin
      ex_unit <= `EX_ALU_UNIT;
      imm  <= $signed(inst[`POS_IMM]);
      imm_tag <= 1;
      pc_tag <= 0;
      store_pc_tag <= 0;
      ce[1] <= 1;
      rs[1] <= inst[`POS_RS1];
      ce[2] <= 0;
      // rs2
      rd_ce <= 1;
      rd <= inst[`POS_RD];
      case (inst[`POS_FUNCT3])
        `ADDI_FUNCT3:  op <= `ALU_ADD;
        `SLTI_FUNCT3:  op <= `ALU_SLT;
        `SLTIU_FUNCT3: op <= `ALU_SLTU;
        `XORI_FUNCT3:  op <= `ALU_XOR;
        `ORI_FUNCT3:   op <= `ALU_OR;
        `ANDI_FUNCT3:  op <= `ALU_AND;
        // shift
        `SLLI_FUNCT3:  begin
                         op <= `ALU_SLL;
                         imm <= $signed(inst[`POS_SHAMT]);
                       end
        `SRLAI_FUNCT3: begin
                         if (inst[30])
                           op <= `ALU_SRL;
                         else
                           op <= `ALU_SRA;
                         imm <= $signed(inst[`POS_SHAMT]);
                       end
        default: op <= `ALU_NOP;
      endcase
    end
  endtask

  task decode_lui_type;
    ex_unit <= `EX_FORWARDER_UNIT;
    imm[`POS_IMM_UI] <= inst[`POS_IMM_UI];
    imm[11:0] <= 0;
    imm_tag <= 1;
    pc_tag <= 0;
    store_pc_tag <= 0;
    ce[1] <= 0;
    ce[2] <= 0;
    // rs[1/2];
    rd_ce <= 1;
    rd <= inst[`POS_RD];
  endtask

  task decode_auipc_type;
    ex_unit <= `EX_ALU_UNIT;
    imm[`POS_IMM_UI] <= inst[`POS_IMM_UI];
    imm[11:0] <= 0;
    imm_tag <= 1;
    pc_tag <= 1;
    store_pc_tag <= 0;
    ce[1] <= 0;
    ce[2] <= 0;
    // rs[1/2];
    rd_ce <= 1;
    rd <= inst[`POS_RD];
    op <= `ALU_ADD;
  endtask

  task decode_jal_type;
    begin
      ex_unit <= `EX_ALU_UNIT;
      imm <= $signed({inst[31:31], inst[19:12], inst[20:20], inst[30:21]}) << 1;
      imm_tag <= 1;
      pc_tag <= 1;
      store_pc_tag <= 1;
      ce[1] <= 0;
      ce[2] <= 0;
      // rs12
      rd_ce <= 1;
      rd <= inst[`POS_RD];
      op <= `ALU_ADD;

      stall <= 1;
    end
  endtask

  task decode_jalr_type;
    begin
      ex_unit <= `EX_ALU_UNIT;
      imm <= $signed(inst[`POS_IMM]);
      imm_tag <= 1;
      pc_tag <= 0;
      store_pc_tag <= 1;
      ce[1] <= 1;
      rs[1] <= inst[`POS_RS1];
      ce[2] <= 0;
      // rs[2]
      rd_ce <= 1;
      rd <= inst[`POS_RD];
      op <= `ALU_ADD;

      stall <= 1;
    end
  endtask

  task decode_load_type;
    ex_unit <= `EX_MEM_UNIT;
    imm <= $signed(inst[`POS_IMM]);
    imm_tag <= 1;
    pc_tag <= 0;
    store_pc_tag <= 0;
    ce[1] <= 1;
    rs[1] <= inst[`POS_RS1];
    ce[2] <= 0;
    // rs2
    rd_ce <= 1;
    rd <= inst[`POS_RD];
    load_tag <= 1;
  endtask

  // TODO
  task decode_store_type;
    ex_unit <= `EX_MEM_UNIT;
  endtask

  always @ ( * ) begin
    if (rst)
      reset;
    else begin
      case (inst[`POS_OPCODE])
        `R_TYPE_OPCODE: decode_rtype;
        `I_TYPE_OPCODE: decode_itype;
        `LUI_OPCODE:    decode_lui_type;
        `AUIPC_OPCPDE:  decode_auipc_type;
        `JAL_OPCODE:    decode_jal_type;
        `JALR_OPCODE:   decode_jalr_type;
        // TODO: branch
        `LOAD_OPCODE:   decode_load_type;
        default: ;
      endcase
    end
  end

endmodule : decoder
