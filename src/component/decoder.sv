`include "common_def.h"

module decoder (
  input rst,

  input [`COMMON_WIDTH] inst,
  input [`COMMON_WIDTH] pc_addr,

  decoder_control_inf.decoder  control,
  decoder_reg_file_inf.decoder decoder_reg_file
  );

  always @ ( * ) begin
    if (rst)
      reset;
    else begin
      clean_output;
      case (inst[`POS_OPCODE])
        `R_TYPE_OPCODE: decode_rtype;
        `I_TYPE_OPCODE: decode_itype;
        `LUI_OPCODE:    decode_lui_type;
        `AUIPC_OPCPDE:  decode_auipc_type;
        `JAL_OPCODE:    decode_jal_type;
        `JALR_OPCODE:   decode_jalr_type;
        `BRANCH_OPCODE: decode_branch_type;
        `LOAD_OPCODE:   decode_load_type;
        `STORE_OPCODE:  decode_store_type;
        default: decode_empty_type;
      endcase
    end
  end

  task decode_rtype;
    begin
      control.ex_unit <= `EX_ALU_UNIT;
      control.rs_en[1] <= 1;
      control.rs_en[2] <= 1;
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
      decoder_reg_file.rs[2] <= inst[`POS_RS2];
      decoder_reg_file.rd_en <= 1;
      decoder_reg_file.rd <= inst[`POS_RD];
      case (merge_funct73(inst[`POS_FUNCT7], inst[`POS_FUNCT3]))
        `ADD_FUNCT73:  control.op <= `ALU_ADD;
        `SUB_FUNCT73:  control.op <= `ALU_SUB;
        `SLL_FUNCT73:  control.op <= `ALU_SLL;
        `SLT_FUNCT73:  control.op <= `ALU_SLT;
        `SLTU_FUNCT73: control.op <= `ALU_SLTU;
        `XOR_FUNCT73:  control.op <= `ALU_XOR;
        `SRL_FUNCT73:  control.op <= `ALU_SRL;
        `SRA_FUNCT73:  control.op <= `ALU_SRA;
        `OR_FUNCT73:   control.op <= `ALU_OR;
        `AND_FUNCT73:  control.op <= `ALU_AND;
        default:       control.op <= `ALU_NOP;
      endcase
    end
  endtask

  task decode_itype;
    begin
      control.ex_unit <= `EX_ALU_UNIT;
      control.imm     <= $signed(inst[`POS_IMM]);
      control.imm_en  <= 1;
      control.rs_en[1] <= 1;
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
      decoder_reg_file.rd_en <= 1;
      decoder_reg_file.rd    <= inst[`POS_RD];
      case (inst[`POS_FUNCT3])
        `ADDI_FUNCT3:  control.op <= `ALU_ADD;
        `SLTI_FUNCT3:  control.op <= `ALU_SLT;
        `SLTIU_FUNCT3: control.op <= `ALU_SLTU;
        `XORI_FUNCT3:  control.op <= `ALU_XOR;
        `ORI_FUNCT3:   control.op <= `ALU_OR;
        `ANDI_FUNCT3:  control.op <= `ALU_AND;
        // shift
        `SLLI_FUNCT3:  begin
                         control.op <= `ALU_SLL;
                         control.imm <= $unsigned(inst[`POS_SHAMT]);
                       end
        `SRLAI_FUNCT3: begin
                         if (inst[30]) control.op <= `ALU_SRL;
                         else control.op <= `ALU_SRA;
                         control.imm <= $signed(inst[`POS_SHAMT]);
                       end
        default: control.op <= `ALU_NOP;
      endcase
    end
  endtask

  task decode_lui_type;
    control.ex_unit <= `EX_FORWARDER_UNIT;
    control.imm[`POS_IMM_UI] <= inst[`POS_IMM_UI];
    control.imm[11:0] <= 0;
    control.imm_en <= 1;
    decoder_reg_file.rd_en <= 1;
    decoder_reg_file.rd <= inst[`POS_RD];
  endtask

  task decode_auipc_type;
    control.ex_unit <= `EX_ALU_UNIT;
    control.imm[`POS_IMM_UI] <= inst[`POS_IMM_UI];
    control.imm[11:0] <= 0;
    control.imm_en <= 1;
    control.pc_en <= 1;
    decoder_reg_file.rd_en <= 1;
    decoder_reg_file.rd <= inst[`POS_RD];
    control.op <= `ALU_ADD;
  endtask

  task decode_jal_type;
    begin
      control.ex_unit <= `EX_JUMP_UNIT;
      control.imm <= $signed({inst[31:31], inst[19:12], inst[20:20], inst[30:21], 1'b0});
      control.imm_en <= 1;
      control.rs_en[1] <= 1;
      decoder_reg_file.rs[1] <= 0;
      decoder_reg_file.rd_en <= 1;
      decoder_reg_file.rd <= inst[`POS_RD];
      control.op <= `OP_JAL;

      control.stall <= 1;
    end
  endtask

  task decode_jalr_type;
    begin
      control.ex_unit <= `EX_JUMP_UNIT;
      control.imm <= $signed({inst[31:31], inst[19:12], inst[20:20], inst[30:21], 1'b0});
      control.imm_en <= 1;
      control.rs_en[1] <= 1;
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
      decoder_reg_file.rd_en <= 1;
      decoder_reg_file.rd <= inst[`POS_RD];
      control.op <= `OP_JAL;

      control.stall <= 1;
    end
  endtask

  task decode_branch_type;
    begin
      control.ex_unit <= `EX_BRANCH_UNIT;
      control.rs_en[1] <= 1;
      control.rs_en[2] <= 1;
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
      decoder_reg_file.rs[2] <= inst[`POS_RS2];
      control.offset <= $signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
      case (inst[`POS_FUNCT3])
        `BEQ_FUNCT3: control.op <= `OP_BEQ;
        `BNE_FUNCT3: control.op <= `OP_BNE;
        `BLT_FUNCT3: control.op <= `OP_BLT;
        `BGE_FUNCT3: control.op <= `OP_BGE;
        `BLTU_FUNCT3: control.op <= `OP_BLTU;
        `BGEU_FUNCT3: control.op <= `OP_BGEU;
        default: ;
      endcase
      control.stall <= 1;
    end
  endtask

  task decode_load_type;
    begin
      control.ex_unit <= `EX_MEM_UNIT;
      control.rs_en[1] <= 1;
      control.offset   <= $signed({inst[31:20]});
      case (inst[13:12])
        2'b00: control.width <= 1;
        2'b01: control.width <= 2;
        2'b10: control.width <= 4;
        default: ;
      endcase
      control.op <= (inst[14]) ? `OP_LOADU : `OP_LOAD;

      decoder_reg_file.rd_en <= 1;
      decoder_reg_file.rd <= inst[`POS_RD];
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
    end
  endtask

  task decode_store_type;
    begin
      control.ex_unit <= `EX_MEM_UNIT;
      control.rs_en[1] <= 1;
      control.rs_en[2] <= 1;
      control.offset   <= $signed({inst[31:25], inst[11:7]});
      case (inst[13:12])
        2'b00: control.width <= 1;
        2'b01: control.width <= 2;
        2'b10: control.width <= 4;
        default: ;
      endcase
      control.op <= `OP_STORE;
      decoder_reg_file.rs[1] <= inst[`POS_RS1];
      decoder_reg_file.rs[2] <= inst[`POS_RS2];
    end
  endtask

  task decode_empty_type;
    clean_output;
  endtask

  task clean_output;
    control.op       <= `ALU_NOP;
    control.ex_unit  <= `EX_ERR_UNIT;
    control.rs_en[1] <= 0;
    control.rs_en[2] <= 0;
    control.imm      <= 0;
    control.imm_en   <= 0;
    control.pc_en    <= 0;
    control.stall    <= 0;
    control.width    <= 0;
    control.offset   <= 0;

    decoder_reg_file.rs[1] <= 0;
    decoder_reg_file.rs[2] <= 0;
    decoder_reg_file.rd_en <= 0;
    decoder_reg_file.rd    <= 0;
  endtask


  task reset;
    begin
      clean_output;
    end
  endtask

  function [9:0] merge_funct73;
    input  [6:0] funct7;
    input  [2:0] funct3;
    begin
      merge_funct73 = {funct7, funct3};
    end
  endfunction
endmodule : decoder
