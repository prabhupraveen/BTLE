// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Input phy_bit rate 1M, output phy_bit rate 8M
// clk speed 16M

`timescale 1ns / 1ps
module bit_repeat_upsample #
(
  parameter integer SAMPLE_PER_SYMBOL = 8,
  parameter integer SAMPLE_PER_SYMBOL_2M = 8,
  parameter integer SAMPLE_PER_SYMBOL_16X = 16
) (
  input wire clk,
  input wire rst,

  input wire phy_2m_mode,

  input wire phy_bit,
  input wire bit_valid,
  input wire bit_valid_last,

  input wire osr_16x_en,

  output reg  bit_upsample,
  output wire bit_upsample_valid,
  output wire bit_upsample_valid_last
);

reg bit_upsample_valid_r;
reg bit_upsample_valid_last_r;
reg [4:0] repeat_left;
reg sending;
reg bit_valid_last_pending;

wire [4:0] repeat_target;

assign repeat_target = (osr_16x_en ? SAMPLE_PER_SYMBOL_16X[4:0] : (phy_2m_mode ? SAMPLE_PER_SYMBOL_2M[4:0] : SAMPLE_PER_SYMBOL[4:0]));

assign bit_upsample_valid = bit_upsample_valid_r;
assign bit_upsample_valid_last = bit_upsample_valid_last_r;

always @ (posedge clk) begin
  if (rst) begin
    bit_upsample <= 0;
    bit_upsample_valid_r <= 0;
    bit_upsample_valid_last_r <= 0;
    repeat_left <= 0;
    sending <= 0;
    bit_valid_last_pending <= 0;
  end else begin
    bit_upsample_valid_r <= 0;
    bit_upsample_valid_last_r <= 0;

    if (bit_valid) begin
      bit_upsample <= phy_bit;
      bit_upsample_valid_r <= 1;
      repeat_left <= (repeat_target > 0 ? (repeat_target - 1) : 0);
      sending <= 1;
      bit_valid_last_pending <= bit_valid_last;
      if ((repeat_target == 1) && bit_valid_last)
        bit_upsample_valid_last_r <= 1;
    end else if (sending) begin
      bit_upsample_valid_r <= 1;
      if (repeat_left == 0) begin
        sending <= 0;
        if (bit_valid_last_pending)
          bit_upsample_valid_last_r <= 1;
        bit_valid_last_pending <= 0;
      end else begin
        repeat_left <= repeat_left - 1;
      end
    end
  end
end

endmodule

