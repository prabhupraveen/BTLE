// Packet timing enforcement / timeout guard.
// Use this to ensure (a) we detect preamble+AA within a window, and/or
// (b) after hit, packet finishes within a maximum duration.
//
// Typical hookup (conceptual):
// - arm <= 1 when you start listening (or when decode_run goes high)
// - hit_flag from correlator
// - decode_end from RX core
// - outputs: abort (pulse), timeout flags

`timescale 1ns/1ps

module packet_timing_enforce #(
  parameter integer CLK_HZ = 16000000,
  parameter integer PREAMBLE_AA_TIMEOUT_US = 80,  // how long to wait for hit before abort
  parameter integer PKT_MAX_US = 4000             // max packet time after hit before abort
)(
  input  wire clk,
  input  wire rst,

  input  wire arm,         // start timing when high
  input  wire hit_flag,     // AA detected
  input  wire decode_end,   // packet decode ended (good or bad)

  output reg  abort,        // 1-cycle pulse requesting abort/reset of decoder chain
  output reg  timeout_wait_hit,
  output reg  timeout_in_pkt
);

  localparam integer PRE_TO = (CLK_HZ/1000000)*PREAMBLE_AA_TIMEOUT_US;
  localparam integer PKT_TO = (CLK_HZ/1000000)*PKT_MAX_US;

  reg armed_d;
  reg in_pkt;

  reg [31:0] cnt_wait_hit;
  reg [31:0] cnt_in_pkt;

  always @(posedge clk) begin
    if (rst) begin
      abort <= 1'b0;
      timeout_wait_hit <= 1'b0;
      timeout_in_pkt <= 1'b0;

      armed_d <= 1'b0;
      in_pkt <= 1'b0;

      cnt_wait_hit <= 32'd0;
      cnt_in_pkt <= 32'd0;
    end else begin
      abort <= 1'b0; // default pulse low

      armed_d <= arm;

      // (Re)arm on rising edge of arm
      if (arm && !armed_d) begin
        timeout_wait_hit <= 1'b0;
        timeout_in_pkt <= 1'b0;
        in_pkt <= 1'b0;
        cnt_wait_hit <= 32'd0;
        cnt_in_pkt <= 32'd0;
      end

      if (arm) begin
        if (!in_pkt) begin
          // waiting for hit
          if (hit_flag) begin
            in_pkt <= 1'b1;
            cnt_in_pkt <= 32'd0;
          end else begin
            cnt_wait_hit <= cnt_wait_hit + 1;
            if (cnt_wait_hit >= (PRE_TO-1)) begin
              timeout_wait_hit <= 1'b1;
              abort <= 1'b1;
              // keep timing until re-armed
            end
          end
        end else begin
          // in packet after hit
          if (decode_end) begin
            in_pkt <= 1'b0;
            // finished; leave flags as-is
          end else begin
            cnt_in_pkt <= cnt_in_pkt + 1;
            if (cnt_in_pkt >= (PKT_TO-1)) begin
              timeout_in_pkt <= 1'b1;
              abort <= 1'b1;
            end
          end
        end
      end
    end
  end

endmodule