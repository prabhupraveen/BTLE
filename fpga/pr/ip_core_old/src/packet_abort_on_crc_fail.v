// Packet abort on CRC fail.
// In your current btle_rx.v, all phases run until end; decode_end_early happens only on CRC OK.
// If you want to stop work early when CRC fails (or after N failures), use this block to
// request abort/reset after the first decode_end with crc_ok=0 (or after a programmable limit).

`timescale 1ns/1ps

module packet_abort_on_crc_fail #(
  parameter integer FAIL_LIMIT = 1
)(
  input  wire clk,
  input  wire rst,

  input  wire enable,
  input  wire decode_end,
  input  wire crc_ok,

  output reg  abort_pulse,
  output reg  [15:0] fail_count
);

  always @(posedge clk) begin
    if (rst) begin
      abort_pulse <= 1'b0;
      fail_count <= 0;
    end else begin
      abort_pulse <= 1'b0;

      if (decode_end && !crc_ok) begin
        if (enable) begin
          if (fail_count < FAIL_LIMIT) fail_count <= fail_count + 1;
          if (fail_count == (FAIL_LIMIT-1)) begin
            abort_pulse <= 1'b1;
          end
        end
      end

      // Optionally clear fail_count on good packet end
      if (decode_end && crc_ok) begin
        fail_count <= 0;
      end
    end
  end

endmodule