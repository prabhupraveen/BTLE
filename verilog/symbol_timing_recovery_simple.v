// Symbol timing recovery (simple): choose best sampling phase based on
// "decision magnitude" metric and output decimated samples at 1Msps.
//
// In your current design, you already do 8-phase parallel decode.
// This block is for an alternate (cheaper) approach: pick best phase and track it.
// It's not a full PLL; it's a windowed energy/max-metric phase selector.
//
// Inputs:
// - decision_in: signed demod decision (e.g., i0*q1 - i1*q0) from gfsk_demodulation
// - decision_valid: 8x oversampled valid
// Output:
// - phase_sel: chosen phase [0..SPS-1]
// - sym_strobe: 1-cycle pulse at symbol rate
// - decision_sym: decision sample at chosen phase
//
// Note: if you don't have decision_in available today, you can use |i|+|q|
// or just reuse decision_in already computed in gfsk_demodulation.

`timescale 1ns/1ps

module symbol_timing_recovery_simple #(
  parameter integer SPS = 8,
  parameter integer DEC_W = 32,
  parameter integer PH_W = 3,
  parameter integer UPDATE_PERIOD_SYM = 32  // update phase decision every N symbols
)(
  input  wire clk,
  input  wire rst,

  input  wire signed [DEC_W-1:0] decision_in,
  input  wire decision_valid,
  input  wire [15:0] update_period_sym_runtime,

  output reg  [PH_W-1:0] phase_sel,
  output reg  sym_strobe,
  output reg  signed [DEC_W-1:0] decision_sym
);

  reg [PH_W-1:0] phase_cnt;

  // accumulate metric per phase over UPDATE_PERIOD_SYM symbols
  reg [31:0] sym_cnt;
  reg [47:0] metric [0:SPS-1]; // wide enough sum(|decision|)

  integer p;

  wire [DEC_W-1:0] abs_decision = decision_in[DEC_W-1] ? (~decision_in + 1'b1) : decision_in;

  always @(posedge clk) begin
    if (rst) begin
      phase_cnt <= 0;
      phase_sel <= 0;
      sym_strobe <= 0;
      decision_sym <= 0;
      sym_cnt <= 0;
      for (p=0; p<SPS; p=p+1) metric[p] <= 0;
    end else begin
      sym_strobe <= 1'b0;

      if (decision_valid) begin
        phase_cnt <= phase_cnt + 1'b1;

        // accumulate metric for current phase
        metric[phase_cnt] <= metric[phase_cnt] + abs_decision;

        // produce symbol strobe at currently selected phase
        if (phase_cnt == phase_sel) begin
          sym_strobe <= 1'b1;
          decision_sym <= decision_in;

          sym_cnt <= sym_cnt + 1;
          if (sym_cnt == ((update_period_sym_runtime == 0 ? UPDATE_PERIOD_SYM[15:0] : update_period_sym_runtime)-1)) begin
            // pick best phase
            sym_cnt <= 0;

            // find argmax metric
            begin : pick
              reg [47:0] best_m;
              reg [PH_W-1:0] best_p;
              best_m = metric[0];
              best_p = 0;
              for (p=1; p<SPS; p=p+1) begin
                if (metric[p] > best_m) begin
                  best_m = metric[p];
                  best_p = p[PH_W-1:0];
                end
              end
              phase_sel <= best_p;
            end

            // clear metrics for next window
            for (p=0; p<SPS; p=p+1) metric[p] <= 0;
          end
        end
      end
    end
  end

endmodule