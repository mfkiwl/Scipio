`include "define.h"

// TODO: decode S/... type, output other types

module id_decoder (
  input rst,

  input [`COMMON_WIDTH] inst,

  output reg [`ALU_TYPE_WIDTH]   alu_type,
  output reg                     write_alu_result_tag,
  output reg                     imm_tag,
  output reg [`COMMON_WIDTH]     extended_imm,
  output reg [`REG_NUM]          rd,
  output reg [`REG_NUM]          rs1,
  output reg [`REG_NUM]          rs2
  );

  always @(posedge rst) begin
    write_alu_result_tag <= 0;
    imm_tag <= 0;
    alu_type <= 0;
    extended_imm <= 0;
    rd  <= 0;
    rs1 <= 0;
    rs2 <= 0;
  end

  function [9:0] merge_funct73;
    input  [6:0] funct7;
    input  [2:0] funct3;
    begin
      merge_funct73 = {funct7, funct3};
    end
  endfunction

  task decode_rtype;
    begin
      write_alu_result_tag <= 1'b1;
      imm_tag <= 1'b0;
      rs1 <= inst[`POS_RS1];
      rs2 <= inst[`POS_RS2];
      rd  <= inst[`POS_RD];
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
      extended_imm <= $signed(inst[`POS_IMM]);
      write_alu_result_tag <= 1'b1;
      imm_tag <= 1'b1;
      rs1 <= inst[`POS_RS1];
      rd  <= inst[`POS_RD];
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
    case (inst[`POS_OPCODE])
      `R_TYPE_OPCODE: decode_rtype;
      `I_TYPE_OPCODE: decode_itype;
      default:;
    endcase
  end

endmodule // id_decoder
