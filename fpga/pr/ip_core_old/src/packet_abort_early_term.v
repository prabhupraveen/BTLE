// Packet abort / early termination controller.
// Generates abort request if:
// - external abort_req asserted
// - timing_enforcer abort asserted
// - crc_fail_abort enabled and crc_fail observed at decode_end
//
// Hookup idea:
// - Feed its abort_pulse into btle_rx_core reset OR into btle_rx's rst|... logic.

`timescale 1ns/1ps

module packet_abort_early_term #(
  parameter integer HOLD_CYCLES = 1 // pulse width; keep 1 for reset pulse
)(
  input  wire clk,
  input  wire rst,

  input  wire abort_req,          // external request (e.g., MAC asks abort)
  input  wire timing_abort,       // from packet_timing_enforce.abort
  input  wire decode_end,         // from rx core
  input  wire crc_ok,             // from rx core
  input  wire abort_on_crc_fail,  // config enable

  output reg  abort_pulse,
  output reg  aborted,
  output reg  crc_fail_seen
);

  reg [31:0] hold;

  always @(posedge clk) begin
    if (rst) begin
      abort_pulse <= 1'b0;
      aborted <= 1'b0;
      crc_fail_seen <= 1'b0;
      hold <= 0;
    end else begin
      abort_pulse <= 1'b0;

      // latch crc fail at end
      if (decode_end && !crc_ok) begin
        crc_fail_seen <= 1'b1;
        if (abort_on_crc_fail) begin
          aborted <= 1'b1;
          hold <= HOLD_CYCLES;
        end
      end

      if (abort_req || timing_abort) begin
        aborted <= 1'b1;
        hold <= HOLD_CYCLES;
      end

      if (hold != 0) begin
        abort_pulse <= 1'b1;
        hold <= hold - 1;
      end
    end
  end

endmodule