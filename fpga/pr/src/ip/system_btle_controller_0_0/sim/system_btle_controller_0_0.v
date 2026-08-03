// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: user.org:user:btle_controller:1.0
// IP Revision: 2

`timescale 1ns/1ps

(* IP_DEFINITION_SOURCE = "package_project" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module system_btle_controller_0_0 (
  rf_clk,
  rf_rst,
  bb_clk,
  bb_rst,
  gpio,
  uart_rx,
  uart_tx,
  rf_gpio,
  tx_iq_signal_ext,
  tx_iq_valid_ext,
  tx_iq_valid_last_ext,
  rx_iq_signal_ext,
  rx_iq_valid_ext,
  baremetal_phy_intf_mode,
  ext_tx_gauss_filter_tap_index,
  ext_tx_gauss_filter_tap_value,
  ext_tx_cos_table_write_address,
  ext_tx_cos_table_write_data,
  ext_tx_sin_table_write_address,
  ext_tx_sin_table_write_data,
  ext_tx_preamble,
  ext_tx_access_address,
  ext_tx_crc_state_init_bit,
  ext_tx_crc_state_init_bit_load,
  ext_tx_channel_number,
  ext_tx_channel_number_load,
  ext_tx_pdu_octet_mem_data,
  ext_tx_pdu_octet_mem_addr,
  ext_tx_start,
  ext_tx_phy_bit,
  ext_tx_phy_bit_valid,
  ext_tx_phy_bit_valid_last,
  ext_tx_bit_upsample,
  ext_tx_bit_upsample_valid,
  ext_tx_bit_upsample_valid_last,
  ext_tx_bit_upsample_gauss_filter,
  ext_tx_bit_upsample_gauss_filter_valid,
  ext_tx_bit_upsample_gauss_filter_valid_last,
  ext_rx_unique_bit_sequence,
  ext_rx_channel_number,
  ext_rx_crc_state_init_bit,
  ext_rx_hit_flag,
  ext_rx_decode_run,
  ext_rx_decode_end,
  ext_rx_crc_ok,
  ext_rx_best_phase,
  ext_rx_payload_length,
  ext_rx_pdu_octet_mem_addr,
  ext_rx_pdu_octet_mem_data
);

(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rf_clk CLK" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rf_clk, ASSOCIATED_RESET rf_rst, FREQ_HZ 8000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_1_clk_out1, INSERT_VIP 0" *)
input wire rf_clk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rf_rst RST" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rf_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
input wire rf_rst;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 bb_clk CLK" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME bb_clk, ASSOCIATED_RESET bb_rst, FREQ_HZ 16000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_1_clk_out1, INSERT_VIP 0" *)
input wire bb_clk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 bb_rst RST" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME bb_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
input wire bb_rst;
input wire [7 : 0] gpio;
input wire uart_rx;
output wire uart_tx;
input wire [7 : 0] rf_gpio;
output wire [63 : 0] tx_iq_signal_ext;
output wire tx_iq_valid_ext;
output wire tx_iq_valid_last_ext;
input wire [63 : 0] rx_iq_signal_ext;
input wire rx_iq_valid_ext;
input wire baremetal_phy_intf_mode;
input wire [3 : 0] ext_tx_gauss_filter_tap_index;
input wire [15 : 0] ext_tx_gauss_filter_tap_value;
input wire [10 : 0] ext_tx_cos_table_write_address;
input wire [7 : 0] ext_tx_cos_table_write_data;
input wire [10 : 0] ext_tx_sin_table_write_address;
input wire [7 : 0] ext_tx_sin_table_write_data;
input wire [7 : 0] ext_tx_preamble;
input wire [31 : 0] ext_tx_access_address;
input wire [23 : 0] ext_tx_crc_state_init_bit;
input wire ext_tx_crc_state_init_bit_load;
input wire [5 : 0] ext_tx_channel_number;
input wire ext_tx_channel_number_load;
input wire [7 : 0] ext_tx_pdu_octet_mem_data;
input wire [8 : 0] ext_tx_pdu_octet_mem_addr;
input wire ext_tx_start;
output wire ext_tx_phy_bit;
output wire ext_tx_phy_bit_valid;
output wire ext_tx_phy_bit_valid_last;
output wire ext_tx_bit_upsample;
output wire ext_tx_bit_upsample_valid;
output wire ext_tx_bit_upsample_valid_last;
output wire [15 : 0] ext_tx_bit_upsample_gauss_filter;
output wire ext_tx_bit_upsample_gauss_filter_valid;
output wire ext_tx_bit_upsample_gauss_filter_valid_last;
input wire [31 : 0] ext_rx_unique_bit_sequence;
input wire [5 : 0] ext_rx_channel_number;
input wire [23 : 0] ext_rx_crc_state_init_bit;
output wire ext_rx_hit_flag;
output wire ext_rx_decode_run;
output wire ext_rx_decode_end;
output wire ext_rx_crc_ok;
output wire [2 : 0] ext_rx_best_phase;
output wire [7 : 0] ext_rx_payload_length;
input wire [8 : 0] ext_rx_pdu_octet_mem_addr;
output wire [7 : 0] ext_rx_pdu_octet_mem_data;

  btle_controller #(
    .CLK_FREQUENCE(100000000),
    .BAUD_RATE(115200),
    .PARITY("NONE"),
    .FRAME_WD(8),
    .RF_IQ_BIT_WIDTH(64),
    .RF_I_OR_Q_BIT_WIDTH(16),
    .CRC_STATE_BIT_WIDTH(24),
    .CHANNEL_NUMBER_BIT_WIDTH(6),
    .SAMPLE_PER_SYMBOL(8),
    .GAUSS_FILTER_BIT_WIDTH(16),
    .NUM_TAP_GAUSS_FILTER(17),
    .VCO_BIT_WIDTH(16),
    .SIN_COS_ADDR_BIT_WIDTH(11),
    .IQ_BIT_WIDTH(8),
    .GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(1),
    .GFSK_DEMODULATION_BIT_WIDTH(16),
    .LEN_UNIQUE_BIT_SEQUENCE(32),
    .NUM_BIT_PAYLOAD_LENGTH(8),
    .BRAM_DEPTH(32768),
    .BRAM_ADDR_WIDTH(15),
    .BRAM_DATA_WIDTH(32),
    .BRAM_ADDR_WIDTH_IN_BYTE(17)
  ) inst (
    .rf_clk(rf_clk),
    .rf_rst(rf_rst),
    .bb_clk(bb_clk),
    .bb_rst(bb_rst),
    .gpio(gpio),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .rf_gpio(rf_gpio),
    .tx_iq_signal_ext(tx_iq_signal_ext),
    .tx_iq_valid_ext(tx_iq_valid_ext),
    .tx_iq_valid_last_ext(tx_iq_valid_last_ext),
    .rx_iq_signal_ext(rx_iq_signal_ext),
    .rx_iq_valid_ext(rx_iq_valid_ext),
    .baremetal_phy_intf_mode(baremetal_phy_intf_mode),
    .ext_tx_gauss_filter_tap_index(ext_tx_gauss_filter_tap_index),
    .ext_tx_gauss_filter_tap_value(ext_tx_gauss_filter_tap_value),
    .ext_tx_cos_table_write_address(ext_tx_cos_table_write_address),
    .ext_tx_cos_table_write_data(ext_tx_cos_table_write_data),
    .ext_tx_sin_table_write_address(ext_tx_sin_table_write_address),
    .ext_tx_sin_table_write_data(ext_tx_sin_table_write_data),
    .ext_tx_preamble(ext_tx_preamble),
    .ext_tx_access_address(ext_tx_access_address),
    .ext_tx_crc_state_init_bit(ext_tx_crc_state_init_bit),
    .ext_tx_crc_state_init_bit_load(ext_tx_crc_state_init_bit_load),
    .ext_tx_channel_number(ext_tx_channel_number),
    .ext_tx_channel_number_load(ext_tx_channel_number_load),
    .ext_tx_pdu_octet_mem_data(ext_tx_pdu_octet_mem_data),
    .ext_tx_pdu_octet_mem_addr(ext_tx_pdu_octet_mem_addr),
    .ext_tx_start(ext_tx_start),
    .ext_tx_phy_bit(ext_tx_phy_bit),
    .ext_tx_phy_bit_valid(ext_tx_phy_bit_valid),
    .ext_tx_phy_bit_valid_last(ext_tx_phy_bit_valid_last),
    .ext_tx_bit_upsample(ext_tx_bit_upsample),
    .ext_tx_bit_upsample_valid(ext_tx_bit_upsample_valid),
    .ext_tx_bit_upsample_valid_last(ext_tx_bit_upsample_valid_last),
    .ext_tx_bit_upsample_gauss_filter(ext_tx_bit_upsample_gauss_filter),
    .ext_tx_bit_upsample_gauss_filter_valid(ext_tx_bit_upsample_gauss_filter_valid),
    .ext_tx_bit_upsample_gauss_filter_valid_last(ext_tx_bit_upsample_gauss_filter_valid_last),
    .ext_rx_unique_bit_sequence(ext_rx_unique_bit_sequence),
    .ext_rx_channel_number(ext_rx_channel_number),
    .ext_rx_crc_state_init_bit(ext_rx_crc_state_init_bit),
    .ext_rx_hit_flag(ext_rx_hit_flag),
    .ext_rx_decode_run(ext_rx_decode_run),
    .ext_rx_decode_end(ext_rx_decode_end),
    .ext_rx_crc_ok(ext_rx_crc_ok),
    .ext_rx_best_phase(ext_rx_best_phase),
    .ext_rx_payload_length(ext_rx_payload_length),
    .ext_rx_pdu_octet_mem_addr(ext_rx_pdu_octet_mem_addr),
    .ext_rx_pdu_octet_mem_data(ext_rx_pdu_octet_mem_data)
  );
endmodule
