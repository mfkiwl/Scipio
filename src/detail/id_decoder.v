`include "define.h"

module id_decoder (
  input rst,

  input [`COMMON_WIDTH] inst,

  // to id/ex
  output reg [`ALU_TYPE_WIDTH]   alu_type,
    // if imm_tag == 1, then the second operand
    // of alu should be imm instead of src2.
  output reg                     imm_tag,
  output reg [`COMMON_WIDTH]     extended_imm,
  output reg [`REG_NUM_WIDTH]    reg_write_out,
    // forwarding information
    // suppose i is the smallest num such that
    // forwarding_at[i] !== 0. Then the reslut
    // of stage[i] should be forwarded to ID.
  output reg [`STAGE_NUM_WIDTH]  forwarding_at,

  // to id_reg_file
  output reg [`REG_NUM_WIDTH]    rs1,
  output reg [`REG_NUM_WIDTH]    rs2
  );

  task reset;
    begin
      alu_type <= 0;
      imm_tag  <= 0;
      extended_imm  <= 0;
      reg_write_out <= 0;
      forwarding_at <= 0;

      rs1 <= 0;
      rs2 <= 0;
    end
  endtask

  function [9:0] merge_funct73;
    input  [6:0] funct7;
    input  [2:0] funct3;
    begin
      merge_funct73 = {funct7, funct3};
    end
  endfunction

  task decode_rtype;
    begin
      imm_tag <= 0;
      reg_write_out <= inst[`POS_RD];
      forwarding_at <= `STAGE_EX;

      rs1 <= inst[`POS_RS1];
      rs2 <= inst[`POS_RS2];

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
      imm_tag <= 1;
      extended_imm  <= $signed(inst[`POS_IMM]);
      reg_write_out <= inst[`POS_RD];
      forwarding_at <= `STAGE_EX;

      rs1 <= inst[`POS_RS1];
      rs2 <= 0;

      case (inst[`POS_FUNCT3])
        `ADDI_FUNCT3:  alu_type <= `ALU_ADD;
        `SLTI_FUNCT3:  alu_type <= `ALU_SLT;
        `SLTIU_FUNCT3: alu_type <= `ALU_SLTU;
        `XORI_FUNCT3:  alu_type <= `ALU_XOR;
        `ORI_FUNCT3:   alu_type <= `ALU_OR;
        `ANDI_FUNCT3:  alu_type <= `ALU_AND;
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
        default:;
      endcase
    end
  end

endmodule // id_decoder
