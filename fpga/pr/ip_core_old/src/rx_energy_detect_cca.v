// Rx Energy Detection (CCA).
// Simple magnitude estimate from I/Q: |I|+|Q| (avoids multiplier).
// Compares averaged energy over a window against a threshold.
//
// Outputs:
// - cca_busy: channel busy (energy above threshold)
// - ed_level: averaged energy (for calibration / threshold tuning)

`timescale 1ns/1ps

module rx_energy_detect_cca #(
  parameter integer IQ_W = 16,
  parameter integer ACC_W = 32,
  parameter integer WINDOW_SAMPLES = 128,
  parameter integer MAG_W = 17  // width of pre-computed magnitude (typically IQ_W+1)
)(
  input  wire clk,
  input  wire rst,

  input  wire signed [IQ_W-1:0] i,
  input  wire signed [IQ_W-1:0] q,
  input  wire iq_valid,
  input  wire [MAG_W-1:0] rx_magnitude,  // rx magnitude from auxiliary_daemon

  input  wire [ACC_W-1:0] ed_threshold,  // compare against average magnitude

  output reg  cca_busy,
  output reg  [ACC_W-1:0] ed_level,
  output reg  ed_valid
);

  // Magnitude computation is performed by auxiliary_daemon (|I| + |Q|).
  // This module uses only the pre-computed rx_magnitude for CCA windowed accumulation.
  wire [MAG_W-1:0] mag = rx_magnitude;

  reg [ACC_W-1:0] acc;
  reg [31:0]      cnt;

  always @(posedge clk) begin
    if (rst) begin
      acc <= 0;
      cnt <= 0;
      ed_level <= 0;
      cca_busy <= 1'b0;
      ed_valid <= 1'b0;
    end else begin
      ed_valid <= 1'b0;

      if (iq_valid) begin
        acc <= acc + {{(ACC_W-MAG_W){1'b0}}, mag};
        cnt <= cnt + 1;

        if (cnt == (WINDOW_SAMPLES-1)) begin
          // average = acc / WINDOW_SAMPLES (power-of-two preferred but not required)
          // For general WINDOW_SAMPLES, we output sum and let software interpret,
          // OR you can set WINDOW_SAMPLES to power-of-two and shift.
          ed_level <= acc / WINDOW_SAMPLES;
          ed_valid <= 1'b1;

          cca_busy <= ((acc / WINDOW_SAMPLES) >= ed_threshold);

          acc <= 0;
          cnt <= 0;
        end
      end
    end
  end

endmodule