// AA correlator with programmable threshold.
// Computes Hamming distance between last LEN bits and AA target.
// Declares hit when (LEN - mismatches) >= threshold.
// Also outputs best_score (number of matches) for tuning/telemetry.
//
// Drop-in replacement for search_unique_bit_sequence.v if you want thresholding.

`timescale 1ns/1ps

module aa_correlator_threshold #(
  parameter integer LEN = 32,
  parameter integer THRESH_W = 6  // enough to represent 0..LEN
)(
  input  wire clk,
  input  wire rst,

  input  wire phy_bit,
  input  wire bit_valid,

  input  wire [LEN-1:0] aa_target,
  input  wire [THRESH_W-1:0] aa_threshold, // e.g. 32 means exact, 28 allows 4 errors

  output reg  hit_flag,               // 1-cycle pulse
  output reg  [THRESH_W-1:0] score    // #matches in window when evaluated
);

  reg [LEN-1:0] shift;
  reg bit_valid_d;

  integer k;
  reg [THRESH_W-1:0] mism;
  reg [THRESH_W-1:0] matches;

  // combinational popcount of XOR
  always @* begin
    mism = {THRESH_W{1'b0}};
    for (k = 0; k < LEN; k = k + 1) begin
      mism = mism + (shift[k] ^ aa_target[k]);
    end
    matches = LEN[THRESH_W-1:0] - mism;
  end

  always @(posedge clk) begin
    if (rst) begin
      shift <= {LEN{1'b0}};
      bit_valid_d <= 1'b0;
      hit_flag <= 1'b0;
      score <= {THRESH_W{1'b0}};
    end else begin
      hit_flag <= 1'b0;
      bit_valid_d <= bit_valid;

      if (bit_valid) begin
        shift[LEN-1] <= phy_bit;
        shift[LEN-2:0] <= shift[LEN-1:1];
      end

      // Evaluate on delayed valid so shift has updated with current bit.
      if (bit_valid_d) begin
        score <= matches;
        if (matches >= aa_threshold) begin
          hit_flag <= 1'b1;
        end
      end
    end
  end

endmodule