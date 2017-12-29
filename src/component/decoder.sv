`include "common_def.h"

module decoder (
  input rst,

  input [`COMMON_WIDTH] inst,
  input [`COMMON_WIDTH] pc_addr,

  output [`EX_UNIT_NUM_WIDTH] ex_unit,

  output [`INST_OP_WIDTH] op,
  output [`COMMON_WIDTH]  imm,
  output                  imm_tag,

  // to reg_file
  output                  ce [1:2],
  output [`REG_NUM_WIDTH] rs [1:2],
  output [`REG_NUM_WIDTH] rd
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
    end
  endtask

  task decode_rtype;
    begin
      ex_unit <= `EX_ALU_UNIT;
      // imm
      imm_tag <= 0;
      ce[1] <= 1;
      rs[1] <= inst[`POS_RS1];
      ce[2] <= 1;
      rs[2] <= inst[`POS_RS2];
      rd <= inst[`POS_RD];
      case (merge_funct73(inst[`POS_FUNCT7], inst[`POS_FUNCT3]))
        `ADD_FUNCT73:  alu_type <= `ALU_ADD;
        `SUB_FUNCT73:  alu_type <= `ALU_SUB;
        `SLL_FUNCT73:  alu_type <= `ALU_SLL;
        `SLT_FUNCT73:  alu_type <= `ALU_SLT;
        `SLTU_FUNCT73: alu_type <= `ALU_SLTU;
        `XOR_FUNCT73:  alu_type <= `ALU_XOR;
        `SRL_FUNCT73:  alu_type <= `ALU_SRL;
        `SRA_FUNCT73:  alu_type <= `ALU_SRA;
        `OR_FUNCT73:   alu_type <= `ALU_OR;
        `AND_FUNCT73:  alu_type <= `ALU_AND;
        default: alu_type <= `ALU_NOP;
      endcase
    end
  endtask

  task decode_itype;
    begin
      ex_unit <= `EX_ALU_UNIT;
      imm  <= $signed(inst[`POS_IMM]);
      imm_tag <= 1;
      ce[1] <= 1;
      rs[1] <= inst[`POS_RS1];
      ce[2] <= 0;
      // rs2
      rd <= inst[`POS_RD];
      case (inst[`POS_FUNCT3])
        `ADDI_FUNCT3:  alu_type <= `ALU_ADD;
        `SLTI_FUNCT3:  alu_type <= `ALU_SLT;
        `SLTIU_FUNCT3: alu_type <= `ALU_SLTU;
        `XORI_FUNCT3:  alu_type <= `ALU_XOR;
        `ORI_FUNCT3:   alu_type <= `ALU_OR;
        `ANDI_FUNCT3:  alu_type <= `ALU_AND;
        // shift
        `SLLI_FUNCT3:  begin
                         alu_type <= `ALU_SLL;
                         extended_imm <= $signed(inst[`POS_SHAMT]);
                       end
        `SRLAI_FUNCT3: begin
                         if (inst[30])
                           alu_type <= `ALU_SRL;
                         else
                           alu_type <= `ALU_SRA;
                         extended_imm <= $signed(inst[`POS_SHAMT]);
                       end
        default: alu_type <= `ALU_NOP;
      endcase
    end
  endtask

  always @ ( * ) begin
    if (rst)
      reset;
    else begin
      case (inst[`POS_OPCODE])
        `R_TYPE_OPCODE: decode_rtype;
        `I_TYPE_OPCODE: decode_itype;
        // `LUI_OPCODE:    decode_lui_type;
        // `AUIPC_OPCPDE:  decode_auipc_type;
        default:;
      endcase
    end
  end

endmodule : decoder
