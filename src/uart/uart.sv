/* uart_recv
 * - The receiver should set "en" to 1 at the negedge
 *   of a cycle and check whether the data is available
 *   at every negedge. "en" should be reset to 0 after
 *   the data was token.
 * - "valid" and "completed" are not distinguished
 *   right now. Therefore, a failed communication
 *   will cause undefined behavior.
 * - Usage:
 *   Record a flag "busy". And set "busy" to 1 when
 *   starts to receive data. Then at every negedge,
 *   behave properly according to the flag "busy".
 *   Once the data has been token, reset "busy" to 0.
 */

interface uart_recv_inf;
  bit       en;
  bit [7:0] data;
  bit       valid;

  modport receiver (output en, input  data, valid);
  modport uart     (input  en, output data, valid);
endinterface

interface uart_send_inf;
  bit       en;
  bit [7:0] data;
  bit       completed;

  modport sender (output en, data, input  completed);
  modport uart   (input  en, data, output completed);
endinterface

module uart_comm #(
  parameter BAUDRATE = 1,
  parameter CLOCKRATE = 1
  ) (
  input clk,
  input rst,

  uart_recv_inf.uart  recv,
  uart_send_inf.uart  send,

  input      Rx,
  output reg Tx
  );

  localparam SAMPLE_INTERVAL = CLOCKRATE / BAUDRATE;
  localparam STATUS_IDLE  = 0;
  localparam STATUS_BEGIN = 1;
  localparam STATUS_DATA  = 2;
  localparam STATUS_VALID = 4;
  localparam STATUS_END   = 8;

  /////////////////receive/////////////////////////
  reg [3:0] recv_status;
  reg [2:0] recv_bit; // the number of the bits received
  reg       recv_parity;

  integer recv_cnt;
  reg     recv_start_flag;

  wire sample = (recv_cnt == SAMPLE_INTERVAL / 2);
  //////////////////////////////////////////////////
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset_recv;
    end else begin
      recv.valid <= 0;
      if (recv_start_flag) recv_cnt = (recv_cnt == SAMPLE_INTERVAL - 1) ? 0 : recv_cnt + 1;
      if (recv_status == STATUS_IDLE)
        recv_status_idle;
      if (sample) begin
        case (recv_status)
          STATUS_BEGIN: recv_status_begin;
          STATUS_DATA:  recv_status_data;
          STATUS_VALID: recv_status_valid;
          STATUS_END:   recv_status_end;
          default: ;
        endcase
      end
    end
  end
  //////////////////////////////////////////////////
    task reset_recv;
      begin
        recv.data  <= 0;
        recv.valid <= 0;

        recv_status <= STATUS_IDLE;
        recv_parity <= 0;
        recv_bit <= 0;
        recv_cnt <= 0;
        recv_start_flag <= 0;
      end
    endtask
    task recv_status_idle;
      begin
        recv_status <= STATUS_BEGIN;
        recv_cnt <= 0;
        recv_start_flag <= 1;
      end
    endtask
    task recv_status_begin;
      begin
        if(!Rx) begin
          recv_status <= STATUS_DATA;
          recv_bit <= 0;
          recv_parity <= 0;
        end else begin
          recv_status <= STATUS_IDLE;
          recv_start_flag <= 0;
        end
      end
    endtask
    task recv_status_data;
      begin
        recv_parity <= recv_parity ^ Rx;
        recv.data[recv_bit] <= Rx;
        recv_bit <= recv_bit + 1;
        if(recv_bit == 7)
          recv_status <= STATUS_VALID;
      end
    endtask
    task recv_status_valid;
      begin
        if(recv_parity == Rx)
          recv.valid <= 1;
        recv_status <= STATUS_END;
      end
    endtask
    task recv_status_end;
      begin
        recv_status <= STATUS_IDLE;
        recv_start_flag <= 0;
      end
    endtask
  //////////////////////////////////////////////

  /////////////////send/////////////////////////
  reg [3:0] send_status;
  reg [2:0] send_bit;
  reg send_parity;

  integer send_cnt;
  //////////////////////////////////////////////
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      reset_send;
    end else begin
      send.completed <= 0;
      send_cnt <= (send_cnt == SAMPLE_INTERVAL - 1) ? 0 : send_cnt + 1;
      if (send_cnt == 0) begin
        case (send_status)
          STATUS_IDLE:  send_status_idle;
          // STATUS_BEGIN: send_status_begin;
          STATUS_DATA:  send_status_data;
          STATUS_VALID: send_status_valid;
          STATUS_END:   send_status_end;
        endcase
      end
    end
  end
  //////////////////////////////////////////////
    task reset_send;
      send.completed <= 0;

      send_cnt    <= 0;
      send_status <= STATUS_IDLE;
      send_bit    <= 0;
      send_parity <= 0;
      Tx          <= 1;
    endtask
    task send_status_idle;
      if (send.en) begin
        Tx <= 0;
        send_status <= STATUS_DATA;
        send_bit <= 0;
        send_parity <= 0;
      end
    endtask

    task send_status_data;
      Tx <= send.data[send_bit];
      send_parity <= send_parity ^ send.data[send_bit];
      send_bit <= send_bit + 1;
      if(send_bit == 7)
        send_status <= STATUS_VALID;
    endtask
    task send_status_valid;
      Tx <= send_parity;
      send_status <= STATUS_END;
    endtask
    task send_status_end;
      Tx <= 1;
      send_status <= STATUS_IDLE;
      send.completed <= 1;
    endtask

endmodule : uart_comm
