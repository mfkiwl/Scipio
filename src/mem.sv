`timescale 1ns/1ps

`include "common_def.h"

interface mem_unit_reserv_inf;
  logic [`INST_TAG_WIDTH] target;
  bit   [2:0]             width;
  bit   [`COMMON_WIDTH]   offset;
  bit   [`COMMON_WIDTH]   val[1:2]; // base & src
  logic [`INST_TAG_WIDTH] tag[1:2];
  bit   [`OP_TYPE_WIDTH]  op;

  modport out (output target, width, offset, val, tag, op);
  modport in  (input  target, width, offset, val, tag, op);
endinterface

typedef struct {
  bit valid;

  logic [`INST_TAG_WIDTH] target;
  bit   [2:0]             width;
  bit   [`COMMON_WIDTH]   offset;
  bit   [`COMMON_WIDTH]   val[1:2]; // base & src
  logic [`INST_TAG_WIDTH] tag[1:2];
  bit   [`OP_TYPE_WIDTH]  op;
} mem_reserv_entry;

module mem_unit (
  input clk,
  input rst,

  rob_mem_inf.mem         rob_head_info,
  mem_unit_reserv_inf.in  new_entry,
  rob_broadcast_inf.snoop rob_info,

  mem_dcache_inf.mem      with_dcache,

  output reg [`INST_TAG_WIDTH] target,
  output reg [`COMMON_WIDTH]   result
  );

  mem_reserv_entry entries[0:`RES_ENTRY_NUM-1];

  always @ (negedge clk) begin
    if (rst) begin
      ;
    end else begin
      insert_inst;
      update_val;
      try_issue;
    end
  end

  function integer find_avail;
    input logic [`INST_TAG_WIDTH] head;
    integer i, pos;
    begin
      pos = -1;
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
        if (entries[i].valid
          && entries[i].tag[1] == `TAG_INVALID
          && entries[i].tag[2] == `TAG_INVALID
          && entries[i].target == head)
          pos = i;
      find_avail = pos;
    end
  endfunction

  reg busy;
  task try_issue;
    integer i, pos;
    begin
      target = `TAG_INVALID;
      if (!rob_head_info.valid)
        return;

      if (!with_dcache.busy) begin
        pos = find_avail(rob_head_info.head);
        if (pos !== -1) begin
          busy = 1;
          if (entries[pos].op == `OP_STORE) begin store(pos);
          end else load(pos);
        end
      end
      else begin
        if (entries[pos].op == `OP_STORE) begin
          restore(pos);
        end else begin
          reload(pos);
        end
      end
    end
  endtask

  task store;
    input integer pos;
    reg [31:0] addr;
    begin
      with_dcache.rw_flag = 2;
      with_dcache.addr = entries[pos].val[1] + entries[pos].offset;
      case (entries[pos].width)
        1: store_byte(with_dcache.addr[1:0], entries[pos].val[2]);
        2: store_half(with_dcache.addr[1:0], entries[pos].val[2]);
        4: store_word(with_dcache.addr[1:0], entries[pos].val[2]);
        default: ;
      endcase
    end
  endtask
  task store_byte;
    input bit [1:0]  ali_addr;
    input bit [31:0] data;
    begin
      case (ali_addr)
        2'b00: begin
                with_dcache.write_mask = 4'b0001;
                with_dcache.write_data = {24'b0, data[7:0]};
               end
        2'b01: begin
                with_dcache.write_mask = 4'b0010;
                with_dcache.write_data = {16'b0, data[7:0], 8'b0};
               end
        2'b10: begin
                 with_dcache.write_mask = 4'b0100;
                 with_dcache.write_data = {8'b0, data[7:0], 16'b0};
               end
        default: begin
                   with_dcache.write_mask = 4'b1000;
                   with_dcache.write_data = {data[7:0], 24'b0};
                 end
      endcase
    end
  endtask
  task store_half;
    input bit [1:0]  ali_addr;
    input bit [31:0] data;
    begin
      case (ali_addr)
        2'b00: begin
                with_dcache.write_mask = 4'b0011;
                with_dcache.write_data = {16'b0, data[15:0]};
               end
        2'b01: begin
                with_dcache.write_mask = 4'b0110;
                with_dcache.write_data = {8'b0, data[15:0], 8'b0};
               end
        2'b10: begin
                 with_dcache.write_mask = 4'b1100;
                 with_dcache.write_data = {data[15:0], 16'b0};
               end
        default: $display("unaligned address");
      endcase
    end
  endtask
  task store_word;
    input bit [1:0]  ali_addr;
    input bit [31:0] data;
    begin
      if (ali_addr == 2'b00) begin
        with_dcache.write_mask = 4'b1111;
        with_dcache.write_data = data;
      end else begin
        $display("unaligned address");
      end
    end
  endtask
  task restore;
    input integer pos;
    begin
      if (with_dcache.done) begin
        target = entries[pos].target;
        entries[pos].valid = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask

  task load;
    input integer pos;
    begin
      with_dcache.rw_flag = 1;
      with_dcache.addr = entries[pos].val[1] + entries[pos].offset;
      with_dcache.write_data = 0;
      with_dcache.write_mask = 0;
    end
  endtask
  task reload;
    input integer pos;
    begin
      if (with_dcache.done) begin
        target = entries[pos].target;
        if (entries[pos].op == `OP_LOAD) begin
          case (entries[pos].width)
            1: result = sext_byte(get_byte(with_dcache.addr[1:0], with_dcache.read_data));
            2: result = sext_half(get_half(with_dcache.addr[1:0], with_dcache.read_data));
            4: result = with_dcache.read_data;
            default ;
          endcase
        end
        else begin
          case (entries[pos].width)
            1: result = {24'b0, get_byte(with_dcache.addr[1:0], with_dcache.read_data)};
            2: result = {16'b0, get_half(with_dcache.addr[1:0], with_dcache.read_data)};
            4: result = with_dcache.read_data;
            default ;
          endcase
        end
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask
  function [7:0] get_byte;
    input [1:0] addr_suffix;
    input [31:0] data;

    case(addr_suffix)
    2'b00: get_byte = data[7:0];
    2'b01: get_byte = data[15:8];
    2'b10: get_byte = data[23:16];
    2'b11: get_byte = data[31:24];
    endcase
  endfunction
  function [15:0] get_half;
    input [1:0] addr_suffix;
    input [31:0] data;

    case(addr_suffix)
    2'b00: get_half = data[15:0];
    2'b01: get_half = data[23:8];
    2'b10: get_half = data[31:16];
    default: get_half = 16'b0;
    endcase
  endfunction
  function [31:0] sext_byte;
    input [7:0] in;
    sext_byte = {{24{in[7]}}, in};
  endfunction
  function [31:0] sext_half;
    input [15:0] in;
    sext_half = {{16{in[15]}}, in};
  endfunction



  task update_val_x;
    input [`RES_ENTRY_NUM_WIDTH] pos;
    integer i;
    begin
      for (i = 0; i < `ROB_ENTRY_NUM; i = i + 1)
        if (rob_info.valid[i] && rob_info.ready[i]) begin
          if (rob_info.tag[i] == entries[pos].tag[1]) begin
            entries[pos].val[1] = rob_info.val[i];
            entries[pos].tag[1] = `TAG_INVALID;
          end
          if (rob_info.tag[i] == entries[pos].tag[2]) begin
            entries[pos].val[2] = rob_info.val[i];
            entries[pos].tag[2] = `TAG_INVALID;
          end
        end
    end
  endtask

  task update_val;
    integer i;
    begin
      for (i = 0; i < `RES_ENTRY_NUM; i = i + 1) begin
        if (entries[i].valid)
          update_val_x(i);
      end
    end
  endtask

  task insert_inst;
    integer i, pos;
    begin
      if (new_entry.target !== `TAG_INVALID) begin
        pos = -1;
        for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
          pos = (entries[i].valid) ? pos : i;
        entries[pos].valid = 1;
        entries[pos].target = new_entry.target;
        entries[pos].width = new_entry.width;
        entries[pos].offset = new_entry.offset;
        entries[pos].val = new_entry.val;
        entries[pos].tag = new_entry.tag;
        entries[pos].op = new_entry.op;
      end
    end
  endtask

  // reset
  integer ri;
  always @ (posedge rst) begin
    busy <= 0;
    // full <= 0;
    target <= `TAG_INVALID;
    result <= 0;
    for (ri = 0; ri < `RES_ENTRY_NUM; ri = ri + 1)
      entries[ri].valid <= 0;
  end


  /*
  reg busy;
  task try_issue;
    integer i, pos;
    begin
      target = `TAG_INVALID;
      if (!rob_head_info.valid)
        return;

      if (!busy) begin
        pos = -1;
        for (i = 0; i < `RES_ENTRY_NUM; i = i + 1)
          if (entries[i].valid
            && entries[i].tag[1] == `TAG_INVALID
            && entries[i].tag[2] == `TAG_INVALID
            && entries[i].target == rob_head_info.head)
            pos = i;

        if (pos !== -1) begin
          busy = 1;
          if (entries[pos].op == `OP_STORE) begin store(pos);
          end else load(pos);
        end
      end
      else begin
        if (entries[pos].op == `OP_STORE) begin
          restore(pos);
        end else begin
          reload(pos);
        end
      end
    end
  endtask

//////////////rom////////////////
  rom_inf read();
  rom_inf write();
  rom mem_rom(
    .clk(clk),
    .rst(rst),

    .read(read),
    .write(write)
    );
//////////////store//////////////
  task store;
    input integer pos;
    begin
      write.en = 1;
      write.addr = entries[pos].val[1] + entries[pos].offset;
      write.byte_num = entries[pos].width;
      write.data = entries[pos].val[2];
    end
  endtask
  task restore;
    input integer pos;
    begin
      if (write.done) begin
        write.en = 0;
        target = entries[pos].target;
        entries[pos].valid = 0;
        busy = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask
//////////////load//////////////
  task load;
    input integer pos;
    begin
      read.en = 1;
      read.byte_num = entries[pos].width;
      read.addr = entries[pos].val[1] + entries[pos].offset;
    end
  endtask
  task reload;
    input integer pos;
    begin
      if (read.done) begin
        read.en = 0;
        target = entries[pos].target;
        if (entries[pos].op == `OP_LOAD) begin
          case (entries[pos].width)
            1: result = $signed(read.data[7:0]);
            2: result = $signed(read.data[15:0]);
            4: result = read.data;
            default: ;
          endcase
        end else begin
        case (entries[pos].width)
          1: result = $unsigned(read.data[7:0]);
          2: result = $unsigned(read.data[15:0]);
          4: result = read.data;
          default: ;
        endcase
        end
        entries[pos].valid = 0;
        busy = 0;
      end else begin
        target = `TAG_INVALID;
      end
    end
  endtask
////////////////////////////////
  */

endmodule // mem
