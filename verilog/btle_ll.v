// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: LicenseRef-MyCompany-Commercial

// This link layer module interfaces with the host via UART HCI (Host Controller Interface), 
// and axi lite interface as alternative channel for configuration and control.
// and implements the link layer minimum state machine according to the core spec,
// and control/bridge the phy (btle_tx and btle_rx)

// Testbench:
// btle_rx_btle_ll_pkt_store_sim.tcl

// iverilog -o btle_ll btle_ll.v

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)
// `define KEEP_FOR_DBG

`timescale 1ns / 1ps
module btle_ll # (
  // Width of S_AXI data bus
  parameter integer C_S00_AXI_DATA_WIDTH  = 32,
  // Width of S_AXI address bus
  parameter integer C_S00_AXI_ADDR_WIDTH  = 8,

  // parameter CLK_FREQUENCE = 16_000_000, //hz
  parameter CLK_FREQUENCE = 100_000_000, //hz
  parameter BAUD_RATE     = 115200,     //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY        = "NONE",     //"NONE","EVEN","ODD"
  parameter FRAME_WD      = 8,          //if PARITY="NONE",it can be 5~9;else 5~8

  parameter RF_IQ_BIT_WIDTH = 64,
  parameter RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4),

  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,

  parameter GFSK_DEMODULATION_BIT_WIDTH = 16,

  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter NUM_BIT_PAYLOAD_LENGTH = 8 // 8 bit in the core spec 6.2
) (
  input  wire bb_clk,
  input  wire bb_rst,

  `KEEP_FOR_DBG input  wire ref_1pps,

  // ====to host: UART HCI====
  input  wire uart_rx,
  output wire uart_tx,

  // ==========to phy tx======
  output wire [3:0] tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value,

  output wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data,
  output wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data,

  output wire [7:0]  tx_preamble,

  output wire [31:0] tx_access_address,
  output wire [(CRC_STATE_BIT_WIDTH-1) : 0] tx_crc_state_init_bit,
  output wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number,

  `KEEP_FOR_DBG output wire [7:0] tx_pdu_octet_mem_data,
  `KEEP_FOR_DBG output wire [NUM_BIT_PAYLOAD_LENGTH:0] tx_pdu_octet_mem_addr,  // 1 more addr bit is needed: the octet_valid actually will output 2 bytes header, payload length, 3 bytes CRC
  output wire tx_start,
  input  wire tx_iq_valid_last,

  // =========to phy rx=======
  output wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence,
  output wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number,
  output wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit,

  input  wire rx_hit_flag,
  input  wire rx_decode_run,
  input  wire rx_decode_end,
  input  wire rx_crc_ok,
  input  wire [(NUM_BIT_PAYLOAD_LENGTH-1):0] rx_payload_length,

  `KEEP_FOR_DBG output wire [NUM_BIT_PAYLOAD_LENGTH:0] rx_pdu_octet_mem_addr,  // 1 more addr bit is needed: the octet_valid actually will output 2 bytes header, payload length, 3 bytes CRC
  `KEEP_FOR_DBG input  wire [7:0] rx_pdu_octet_mem_data,

  // ===============Auxiliary Signals================
  `KEEP_FOR_DBG output wire [15:0] ll_gpio,
  output wire ll_itrpt0,
  output wire ll_itrpt1,
  output wire ll_itrpt2,
  output wire ll_itrpt3,
  output wire ll_itrpt4,
  output wire ll_itrpt5,
  output wire ll_itrpt6,
  output wire ll_itrpt7,

  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal,
  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal,
  input wire rx_iq_valid,

  input wire [RF_I_OR_Q_BIT_WIDTH : 0] i_abs_add_q_abs,
  input wire agc_lock_change,
  input wire agc_lock_state,
  input wire [6:0] rf_gain,

  input  wire simulation_en,
  input  wire simulation_rx_ram_read_en,

  // Ports of Axi Slave Bus Interface
  input  wire axi_aclk,
  input  wire axi_aresetn,
  input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0] axi_awaddr,
  input  wire [2 : 0] axi_awprot,
  input  wire axi_awvalid,
  output wire axi_awready,
  input  wire [C_S00_AXI_DATA_WIDTH-1 : 0] axi_wdata,
  input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb,
  input  wire axi_wvalid,
  output wire axi_wready,
  output wire [1 : 0] axi_bresp,
  output wire axi_bvalid,
  input  wire axi_bready,
  input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0] axi_araddr,
  input  wire [2 : 0] axi_arprot,
  input  wire axi_arvalid,
  output wire axi_arready,
  output wire [C_S00_AXI_DATA_WIDTH-1 : 0] axi_rdata,
  output wire [1 : 0] axi_rresp,
  output wire axi_rvalid,
  input  wire axi_rready
);

// =========================AXI registers========================
// from reg0 to 47 for writing to PL
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg0;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg1;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg2;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg3;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg4;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg5;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg6;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg7;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg8;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg9;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg10;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg11;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg12;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg13;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg14;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg15;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg16;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg17;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg18;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg19;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg20;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg21;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg22;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg23;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg24;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg25;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg26;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg27;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg28;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg29;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg30;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg31;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg32;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg33;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg34;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg35;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg36;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg37;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg38;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg39;
// from reg40 for reading from PL
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg40;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg41;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg42;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg43;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg44;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg45;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg46;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg47;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg48;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg49;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg50;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg51;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg52;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg53;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg54;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg55;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg56;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg57;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg58;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg59;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg60;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg61;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg62;
wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg63;

`KEEP_FOR_DBG wire slv_reg_rden;
`KEEP_FOR_DBG wire [5:0] axi_araddr_core;

`KEEP_FOR_DBG wire slv_reg_wren;
`KEEP_FOR_DBG wire [5:0] axi_awaddr_core;

`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1):0] slv_reg39_bb;

// ====================bb clk domain config-path signals====================
`KEEP_FOR_DBG wire [3:0] tx_gauss_filter_tap_index_cfg;
`KEEP_FOR_DBG wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value_cfg;

`KEEP_FOR_DBG wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address_cfg;
`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_cos_table_write_data_cfg;
`KEEP_FOR_DBG wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address_cfg;
`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_sin_table_write_data_cfg;

`KEEP_FOR_DBG wire [7:0]  tx_preamble_cfg;
`KEEP_FOR_DBG wire [31:0] tx_access_address_cfg;
`KEEP_FOR_DBG wire [(CRC_STATE_BIT_WIDTH-1) : 0]      tx_crc_state_init_bit_cfg;
`KEEP_FOR_DBG wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number_cfg;
`KEEP_FOR_DBG wire [7:0] tx_pdu_octet_mem_data_cfg;
`KEEP_FOR_DBG wire [NUM_BIT_PAYLOAD_LENGTH:0] tx_pdu_octet_mem_addr_cfg;
`KEEP_FOR_DBG wire tx_start_cfg;

`KEEP_FOR_DBG wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence_cfg;
`KEEP_FOR_DBG wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number_cfg;
`KEEP_FOR_DBG wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit_cfg;

// ===========================UART========================
// rx
wire [FRAME_WD-1:0] rx_frame;
wire rx_done;
wire frame_error;

// tx
wire frame_en;
wire [FRAME_WD-1:0] data_frame;
wire tx_done;

// ===============link layer state machine================
localparam [2:0] STANDBY                  = 0,
                 ADVERTISING              = 1,
                 INITIATING               = 2,
                 CONNECTION               = 3,
                 ISOCHRONOUS_BROADCASTING = 4,
                 SCANNING                 = 5,
                 SYNCHRONIZATION          = 6;

`KEEP_FOR_DBG reg [2:0] ll_state;

// ====================axi clk domain internal signals for crosing================
`KEEP_FOR_DBG wire [3:0] tx_gauss_filter_tap_index_axi;
`KEEP_FOR_DBG wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value_axi;

`KEEP_FOR_DBG wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address_axi;
`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_cos_table_write_data_axi;
`KEEP_FOR_DBG wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address_axi;
`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_sin_table_write_data_axi;

`KEEP_FOR_DBG wire [7:0]  tx_preamble_axi;

`KEEP_FOR_DBG wire [31:0] tx_access_address_axi;
`KEEP_FOR_DBG wire [(CRC_STATE_BIT_WIDTH-1) : 0]      tx_crc_state_init_bit_axi;
`KEEP_FOR_DBG wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number_axi;

`KEEP_FOR_DBG wire tx_start_axi;

`KEEP_FOR_DBG wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence_axi;
`KEEP_FOR_DBG wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number_axi;
`KEEP_FOR_DBG wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit_axi;

`KEEP_FOR_DBG wire tx_iq_valid_last_axi;
`KEEP_FOR_DBG wire rx_hit_flag_axi;
`KEEP_FOR_DBG wire rx_decode_run_axi;
`KEEP_FOR_DBG wire rx_decode_end_axi;
`KEEP_FOR_DBG wire [(NUM_BIT_PAYLOAD_LENGTH-1):0] rx_payload_length_axi;
`KEEP_FOR_DBG reg  [(NUM_BIT_PAYLOAD_LENGTH-1):0] rx_payload_length_axi_lock;

`KEEP_FOR_DBG reg rx_pkt_parse_active_axi;
`KEEP_FOR_DBG reg [7:0] rx_pkt_header0_axi;
`KEEP_FOR_DBG reg [7:0] rx_pkt_header1_axi;
`KEEP_FOR_DBG reg [7:0] rx_pkt_ctrl_opcode_axi;
`KEEP_FOR_DBG reg [31:0] rx_pkt_conn_aa_axi;
`KEEP_FOR_DBG reg [23:0] rx_pkt_conn_crc_init_axi;
`KEEP_FOR_DBG reg [36:0] rx_pkt_conn_ch_map_axi;
`KEEP_FOR_DBG reg [4:0]  rx_pkt_conn_hop_inc_axi;
`KEEP_FOR_DBG reg rx_pkt_snapshot_toggle_axi;

`KEEP_FOR_DBG wire rx_crc_ok_axi;
`KEEP_FOR_DBG reg  rx_crc_ok_axi_lock;

`KEEP_FOR_DBG wire [15:0] reg_gpio_axi;

`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event0_counter_axi;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event1_counter_axi;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event2_counter_axi;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event3_counter_axi;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event4_counter_axi;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event5_counter_axi;

`KEEP_FOR_DBG wire [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_hit_flag_axi;
`KEEP_FOR_DBG wire [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_decode_end_axi;
`KEEP_FOR_DBG wire [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_hit_flag_lock_by_decode_end_axi;

`KEEP_FOR_DBG wire [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_axi;

`KEEP_FOR_DBG reg  [(C_S00_AXI_DATA_WIDTH-2) : 0] ref_1pps_counter;
`KEEP_FOR_DBG reg  [(C_S00_AXI_DATA_WIDTH-1) : 0] ref_1pps_flip_and_count;

`KEEP_FOR_DBG reg ref_1pps_delay1;
`KEEP_FOR_DBG reg ref_1pps_delay2;
`KEEP_FOR_DBG reg ref_1pps_delay3;

// ====================bb clk domain internal signals for crosing================
`KEEP_FOR_DBG wire [15:0] reg_gpio;

`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event0_counter;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event1_counter;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event2_counter;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event3_counter;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event4_counter;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] event5_counter;

`KEEP_FOR_DBG reg  [(C_S00_AXI_DATA_WIDTH-1) : 0] event0_counter_delay1; // for debug
`KEEP_FOR_DBG reg  [(C_S00_AXI_DATA_WIDTH-1) : 0] event0_counter_delay2; // for debug
`KEEP_FOR_DBG reg  [(C_S00_AXI_DATA_WIDTH-1) : 0] event0_counter_delay3; // for debug
`KEEP_FOR_DBG wire                                event0_event5_unequal; // for debug

`KEEP_FOR_DBG reg  [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_hit_flag;
`KEEP_FOR_DBG reg  [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_decode_end;
`KEEP_FOR_DBG reg  [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp_rx_hit_flag_lock_by_decode_end;

`KEEP_FOR_DBG wire [(2*C_S00_AXI_DATA_WIDTH-1) : 0] timestamp;

`KEEP_FOR_DBG wire slv_reg_rden_bb;
`KEEP_FOR_DBG wire [5:0] axi_araddr_core_bb;

`KEEP_FOR_DBG wire [7:0] rx_pkt_header0_bb;
`KEEP_FOR_DBG wire [7:0] rx_pkt_header1_bb;
`KEEP_FOR_DBG wire [7:0] rx_pkt_ctrl_opcode_bb;
`KEEP_FOR_DBG wire [31:0] rx_pkt_conn_aa_bb;
`KEEP_FOR_DBG wire [23:0] rx_pkt_conn_crc_init_bb;
`KEEP_FOR_DBG wire [36:0] rx_pkt_conn_ch_map_bb;
`KEEP_FOR_DBG wire [4:0]  rx_pkt_conn_hop_inc_bb;
`KEEP_FOR_DBG wire rx_pkt_snapshot_toggle_bb;
`KEEP_FOR_DBG wire rx_crc_ok_axi_lock_bb;

`KEEP_FOR_DBG reg rx_pkt_snapshot_toggle_bb_d;
`KEEP_FOR_DBG reg rx_pkt_snapshot_pulse_bb;

// ====================enhanced LL scheduler signals========================
localparam [5:0] ADV_CH_37 = 6'd37,
                 ADV_CH_38 = 6'd38,
                 ADV_CH_39 = 6'd39;

localparam [31:0] ADV_INTERVAL_TICK_DEFAULT        = 32'd1600000;  // ~16ms @100MHz
localparam [31:0] SCAN_INTERVAL_TICK_DEFAULT       = 32'd10000000; // ~100ms @100MHz
localparam [31:0] SCAN_WINDOW_TICK_DEFAULT         = 32'd5000000;  // ~50ms @100MHz
localparam [31:0] CONN_INTERVAL_TICK_DEFAULT       = 32'd2400000;  // ~24ms @100MHz
localparam [31:0] SUPERVISION_TIMEOUT_TICK_DEFAULT = 32'd100000000; // ~1s @100MHz

`KEEP_FOR_DBG wire ll_sched_enable;
`KEEP_FOR_DBG wire ll_scan_enable;
`KEEP_FOR_DBG wire ll_scan_active;
`KEEP_FOR_DBG wire ll_adv_enable;
`KEEP_FOR_DBG wire ll_conn_enable;
`KEEP_FOR_DBG wire ll_phy_2m_req;

`KEEP_FOR_DBG wire [31:0] adv_interval_ticks_cfg;
`KEEP_FOR_DBG wire [31:0] scan_interval_ticks_cfg;
`KEEP_FOR_DBG wire [31:0] scan_window_ticks_cfg;
`KEEP_FOR_DBG wire [31:0] conn_interval_ticks_cfg;
`KEEP_FOR_DBG wire [31:0] supervision_timeout_ticks_cfg;

`KEEP_FOR_DBG wire [4:0] hop_increment_cfg;
`KEEP_FOR_DBG wire [36:0] channel_map_cfg;

`KEEP_FOR_DBG reg [31:0] adv_interval_cnt;
`KEEP_FOR_DBG reg [31:0] scan_interval_cnt;
`KEEP_FOR_DBG reg [31:0] scan_window_cnt;
`KEEP_FOR_DBG reg [31:0] conn_interval_cnt;
`KEEP_FOR_DBG reg [31:0] supervision_timeout_cnt;

`KEEP_FOR_DBG reg [1:0] adv_channel_seq;
`KEEP_FOR_DBG reg scan_window_open;
`KEEP_FOR_DBG reg connection_established;
`KEEP_FOR_DBG reg tx_pending_empty_pdu;
`KEEP_FOR_DBG reg tx_pending_retransmit;
`KEEP_FOR_DBG reg phy_2m_active;

`KEEP_FOR_DBG reg [15:0] conn_event_counter;
`KEEP_FOR_DBG reg [5:0] conn_data_channel;

`KEEP_FOR_DBG reg [7:0] last_rx_pdu_byte;
`KEEP_FOR_DBG reg [7:0] last_ctrl_opcode;
`KEEP_FOR_DBG reg [7:0] last_rx_header_byte;

`KEEP_FOR_DBG reg tx_start_ll;
`KEEP_FOR_DBG reg [7:0]  tx_preamble_ll;
`KEEP_FOR_DBG reg [31:0] tx_access_address_ll;
`KEEP_FOR_DBG reg [(CRC_STATE_BIT_WIDTH-1) : 0]      tx_crc_state_init_bit_ll;
`KEEP_FOR_DBG reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number_ll;
`KEEP_FOR_DBG reg [7:0] tx_pdu_octet_mem_data_ll;
`KEEP_FOR_DBG reg [NUM_BIT_PAYLOAD_LENGTH:0] tx_pdu_octet_mem_addr_ll;
`KEEP_FOR_DBG reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence_ll;
`KEEP_FOR_DBG reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number_ll;
`KEEP_FOR_DBG reg [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit_ll;

`KEEP_FOR_DBG reg ll_supervision_timeout_pulse;
`KEEP_FOR_DBG reg ll_ctrl_pdu_seen_pulse;
`KEEP_FOR_DBG reg ll_connect_ind_pulse;
`KEEP_FOR_DBG reg ll_phy_update_pulse;

localparam [3:0] LL_PKT_ADV          = 4'd0,
                 LL_PKT_SCAN_REQ     = 4'd1,
                 LL_PKT_SCAN_RSP     = 4'd2,
                 LL_PKT_DATA_EMPTY   = 4'd3,
                 LL_PKT_CTRL_VERSION = 4'd4,
                 LL_PKT_CTRL_FEATURE = 4'd5,
                 LL_PKT_CTRL_CH_MAP  = 4'd6,
                 LL_PKT_CTRL_TERM    = 4'd7;

localparam [7:0] LL_CTRL_VERSION_IND      = 8'h0C,
                 LL_CTRL_FEATURE_REQ      = 8'h08,
                 LL_CTRL_FEATURE_RSP      = 8'h09,
                 LL_CTRL_CHANNEL_MAP_IND  = 8'h01,
                 LL_CTRL_TERMINATE_IND    = 8'h02;

`KEEP_FOR_DBG reg [3:0] ll_tx_pkt_kind;
`KEEP_FOR_DBG reg [15:0] ll_tifs_counter;
`KEEP_FOR_DBG reg ll_tx_after_ifs_pending;
`KEEP_FOR_DBG reg ll_pending_scan_req;
`KEEP_FOR_DBG reg ll_pending_scan_rsp;
`KEEP_FOR_DBG reg ll_pending_ctrl_version;
`KEEP_FOR_DBG reg ll_pending_ctrl_feature;
`KEEP_FOR_DBG reg ll_pending_ctrl_ch_map;
`KEEP_FOR_DBG reg ll_pending_ctrl_terminate;

`KEEP_FOR_DBG reg tx_mem_addr_advancing;
`KEEP_FOR_DBG reg tx_data_sn;
`KEEP_FOR_DBG reg tx_data_nesn;

`KEEP_FOR_DBG reg [36:0] conn_channel_map_active;
`KEEP_FOR_DBG reg [4:0]  conn_hop_increment_active;

`KEEP_FOR_DBG reg connection_established_axi_d1;
`KEEP_FOR_DBG reg connection_established_axi_d2;

wire [3:0] adv_pdu_type_cfg;
wire [5:0] adv_data_len_cfg;
wire [5:0] scan_rsp_data_len_cfg;
wire [47:0] local_addr_cfg;
wire [47:0] peer_addr_cfg;
wire [31:0] conn_access_address_cfg;
wire [23:0] conn_crc_init_cfg;
wire [15:0] tifs_ticks_cfg;

assign adv_pdu_type_cfg      = slv_reg22[3:0];
assign adv_data_len_cfg      = slv_reg22[13:8];
assign scan_rsp_data_len_cfg = slv_reg22[21:16];
assign local_addr_cfg        = {slv_reg24[15:0], slv_reg23};
assign peer_addr_cfg         = {slv_reg25, slv_reg24[31:16]};
assign conn_access_address_cfg = (slv_reg30 == 0 ? tx_access_address_cfg : slv_reg30);
assign conn_crc_init_cfg       = (slv_reg31[23:0] == 0 ? tx_crc_state_init_bit_cfg : slv_reg31[23:0]);
assign tifs_ticks_cfg          = (slv_reg32[15:0] == 0 ? 16'd15000 : slv_reg32[15:0]);

function [7:0] ll_adv_data_byte;
  input [4:0] idx;
  begin
    case (idx)
      5'd0:  ll_adv_data_byte = slv_reg26[7:0];
      5'd1:  ll_adv_data_byte = slv_reg26[15:8];
      5'd2:  ll_adv_data_byte = slv_reg26[23:16];
      5'd3:  ll_adv_data_byte = slv_reg26[31:24];
      5'd4:  ll_adv_data_byte = slv_reg27[7:0];
      5'd5:  ll_adv_data_byte = slv_reg27[15:8];
      5'd6:  ll_adv_data_byte = slv_reg27[23:16];
      5'd7:  ll_adv_data_byte = slv_reg27[31:24];
      5'd8:  ll_adv_data_byte = slv_reg28[7:0];
      5'd9:  ll_adv_data_byte = slv_reg28[15:8];
      5'd10: ll_adv_data_byte = slv_reg28[23:16];
      5'd11: ll_adv_data_byte = slv_reg28[31:24];
      5'd12: ll_adv_data_byte = slv_reg29[7:0];
      5'd13: ll_adv_data_byte = slv_reg29[15:8];
      5'd14: ll_adv_data_byte = slv_reg29[23:16];
      default: ll_adv_data_byte = slv_reg29[31:24];
    endcase
  end
endfunction

always @(*) begin
  tx_pdu_octet_mem_data_ll = 8'h00;
  case (ll_tx_pkt_kind)
    LL_PKT_ADV: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, adv_pdu_type_cfg};
        1: tx_pdu_octet_mem_data_ll = {2'b00, (6'd6 + adv_data_len_cfg)};
        2: tx_pdu_octet_mem_data_ll = local_addr_cfg[7:0];
        3: tx_pdu_octet_mem_data_ll = local_addr_cfg[15:8];
        4: tx_pdu_octet_mem_data_ll = local_addr_cfg[23:16];
        5: tx_pdu_octet_mem_data_ll = local_addr_cfg[31:24];
        6: tx_pdu_octet_mem_data_ll = local_addr_cfg[39:32];
        7: tx_pdu_octet_mem_data_ll = local_addr_cfg[47:40];
        default: tx_pdu_octet_mem_data_ll = ll_adv_data_byte(tx_pdu_octet_mem_addr_ll - 8);
      endcase
    end
    LL_PKT_SCAN_REQ: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = 8'h03;
        1: tx_pdu_octet_mem_data_ll = 8'd12;
        2: tx_pdu_octet_mem_data_ll = local_addr_cfg[7:0];
        3: tx_pdu_octet_mem_data_ll = local_addr_cfg[15:8];
        4: tx_pdu_octet_mem_data_ll = local_addr_cfg[23:16];
        5: tx_pdu_octet_mem_data_ll = local_addr_cfg[31:24];
        6: tx_pdu_octet_mem_data_ll = local_addr_cfg[39:32];
        7: tx_pdu_octet_mem_data_ll = local_addr_cfg[47:40];
        8: tx_pdu_octet_mem_data_ll = peer_addr_cfg[7:0];
        9: tx_pdu_octet_mem_data_ll = peer_addr_cfg[15:8];
        10: tx_pdu_octet_mem_data_ll = peer_addr_cfg[23:16];
        11: tx_pdu_octet_mem_data_ll = peer_addr_cfg[31:24];
        12: tx_pdu_octet_mem_data_ll = peer_addr_cfg[39:32];
        default: tx_pdu_octet_mem_data_ll = peer_addr_cfg[47:40];
      endcase
    end
    LL_PKT_SCAN_RSP: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = 8'h04;
        1: tx_pdu_octet_mem_data_ll = {2'b00, (6'd6 + scan_rsp_data_len_cfg)};
        2: tx_pdu_octet_mem_data_ll = local_addr_cfg[7:0];
        3: tx_pdu_octet_mem_data_ll = local_addr_cfg[15:8];
        4: tx_pdu_octet_mem_data_ll = local_addr_cfg[23:16];
        5: tx_pdu_octet_mem_data_ll = local_addr_cfg[31:24];
        6: tx_pdu_octet_mem_data_ll = local_addr_cfg[39:32];
        7: tx_pdu_octet_mem_data_ll = local_addr_cfg[47:40];
        default: tx_pdu_octet_mem_data_ll = ll_adv_data_byte(tx_pdu_octet_mem_addr_ll - 8);
      endcase
    end
    LL_PKT_CTRL_VERSION: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, tx_data_sn, tx_data_nesn, 2'b11};
        1: tx_pdu_octet_mem_data_ll = 8'd6;
        2: tx_pdu_octet_mem_data_ll = LL_CTRL_VERSION_IND;
        3: tx_pdu_octet_mem_data_ll = 8'h09;
        4: tx_pdu_octet_mem_data_ll = 8'h00;
        5: tx_pdu_octet_mem_data_ll = 8'h01;
        6: tx_pdu_octet_mem_data_ll = 8'h00;
        default: tx_pdu_octet_mem_data_ll = 8'h00;
      endcase
    end
    LL_PKT_CTRL_FEATURE: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, tx_data_sn, tx_data_nesn, 2'b11};
        1: tx_pdu_octet_mem_data_ll = 8'd9;
        2: tx_pdu_octet_mem_data_ll = LL_CTRL_FEATURE_RSP;
        3: tx_pdu_octet_mem_data_ll = slv_reg33[7:0];
        4: tx_pdu_octet_mem_data_ll = slv_reg33[15:8];
        5: tx_pdu_octet_mem_data_ll = slv_reg33[23:16];
        6: tx_pdu_octet_mem_data_ll = slv_reg33[31:24];
        7: tx_pdu_octet_mem_data_ll = slv_reg34[7:0];
        8: tx_pdu_octet_mem_data_ll = slv_reg34[15:8];
        9: tx_pdu_octet_mem_data_ll = slv_reg34[23:16];
        default: tx_pdu_octet_mem_data_ll = slv_reg34[31:24];
      endcase
    end
    LL_PKT_CTRL_CH_MAP: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, tx_data_sn, tx_data_nesn, 2'b11};
        1: tx_pdu_octet_mem_data_ll = 8'd8;
        2: tx_pdu_octet_mem_data_ll = LL_CTRL_CHANNEL_MAP_IND;
        3: tx_pdu_octet_mem_data_ll = channel_map_cfg[7:0];
        4: tx_pdu_octet_mem_data_ll = channel_map_cfg[15:8];
        5: tx_pdu_octet_mem_data_ll = channel_map_cfg[23:16];
        6: tx_pdu_octet_mem_data_ll = channel_map_cfg[31:24];
        7: tx_pdu_octet_mem_data_ll = {3'b000, channel_map_cfg[36:32]};
        8: tx_pdu_octet_mem_data_ll = conn_event_counter[7:0];
        default: tx_pdu_octet_mem_data_ll = conn_event_counter[15:8];
      endcase
    end
    LL_PKT_CTRL_TERM: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, tx_data_sn, tx_data_nesn, 2'b11};
        1: tx_pdu_octet_mem_data_ll = 8'd2;
        2: tx_pdu_octet_mem_data_ll = LL_CTRL_TERMINATE_IND;
        default: tx_pdu_octet_mem_data_ll = slv_reg35[7:0];
      endcase
    end
    default: begin
      case (tx_pdu_octet_mem_addr_ll)
        0: tx_pdu_octet_mem_data_ll = {4'b0000, tx_data_sn, tx_data_nesn, 2'b01};
        1: tx_pdu_octet_mem_data_ll = 8'h00;
        default: tx_pdu_octet_mem_data_ll = 8'h00;
      endcase
    end
  endcase
end

function [5:0] csa1_next_channel;
  input [5:0] current_channel;
  input [4:0] hop_increment;
  input [36:0] channel_map;
  integer i;
  reg [5:0] candidate;
  begin
    candidate = current_channel + hop_increment;
    if (candidate >= 6'd37)
      candidate = candidate - 6'd37;

    if (channel_map[candidate]) begin
      csa1_next_channel = candidate;
    end else begin
      csa1_next_channel = candidate;
      for (i = 0; i < 37; i = i + 1) begin
        if (!channel_map[csa1_next_channel]) begin
          if (csa1_next_channel == 6'd36)
            csa1_next_channel = 0;
          else
            csa1_next_channel = csa1_next_channel + 1;
        end
      end
    end
  end
endfunction

// ===============================================================================
assign ll_gpio                        = reg_gpio;
assign ll_itrpt0                      = rx_decode_end;
assign ll_itrpt1                      = rx_hit_flag;
assign ll_itrpt2                      = ll_supervision_timeout_pulse;
assign ll_itrpt3                      = ll_ctrl_pdu_seen_pulse;
assign ll_itrpt4                      = ll_connect_ind_pulse;
assign ll_itrpt5                      = ll_phy_update_pulse;
assign ll_itrpt6                      = scan_window_open;
assign ll_itrpt7                      = connection_established;

assign ll_sched_enable                = reg_gpio[0];
assign ll_scan_enable                 = reg_gpio[1];
assign ll_scan_active                 = reg_gpio[2];
assign ll_adv_enable                  = reg_gpio[3];
assign ll_conn_enable                 = reg_gpio[4];
assign ll_phy_2m_req                  = reg_gpio[5];

assign adv_interval_ticks_cfg         = (slv_reg14 == 0 ? ADV_INTERVAL_TICK_DEFAULT : slv_reg14);
assign scan_interval_ticks_cfg        = (slv_reg15 == 0 ? SCAN_INTERVAL_TICK_DEFAULT : slv_reg15);
assign scan_window_ticks_cfg          = (slv_reg16 == 0 ? SCAN_WINDOW_TICK_DEFAULT : slv_reg16);
assign conn_interval_ticks_cfg        = (slv_reg17 == 0 ? CONN_INTERVAL_TICK_DEFAULT : slv_reg17);
assign supervision_timeout_ticks_cfg  = (slv_reg18 == 0 ? SUPERVISION_TIMEOUT_TICK_DEFAULT : slv_reg18);

assign hop_increment_cfg              = (slv_reg19[4:0] == 0 ? 5'd5 : slv_reg19[4:0]);
assign channel_map_cfg                = {slv_reg21[4:0], slv_reg20};

assign tx_gauss_filter_tap_index      = tx_gauss_filter_tap_index_cfg;
assign tx_gauss_filter_tap_value      = tx_gauss_filter_tap_value_cfg;
assign tx_cos_table_write_address     = tx_cos_table_write_address_cfg;
assign tx_cos_table_write_data        = tx_cos_table_write_data_cfg;
assign tx_sin_table_write_address     = tx_sin_table_write_address_cfg;
assign tx_sin_table_write_data        = tx_sin_table_write_data_cfg;

assign tx_preamble                    = (ll_sched_enable ? tx_preamble_ll : tx_preamble_cfg);
assign tx_access_address              = (ll_sched_enable ? tx_access_address_ll : tx_access_address_cfg);
assign tx_crc_state_init_bit          = (ll_sched_enable ? tx_crc_state_init_bit_ll : tx_crc_state_init_bit_cfg);
assign tx_channel_number              = (ll_sched_enable ? tx_channel_number_ll : tx_channel_number_cfg);
assign tx_start                       = (ll_sched_enable ? (tx_start_ll | tx_start_cfg) : tx_start_cfg);
assign tx_pdu_octet_mem_data          = (ll_sched_enable ? tx_pdu_octet_mem_data_ll : tx_pdu_octet_mem_data_cfg);
assign tx_pdu_octet_mem_addr          = (ll_sched_enable ? tx_pdu_octet_mem_addr_ll : tx_pdu_octet_mem_addr_cfg);

assign rx_unique_bit_sequence         = (ll_sched_enable ? rx_unique_bit_sequence_ll : rx_unique_bit_sequence_cfg);
assign rx_channel_number              = (ll_sched_enable ? rx_channel_number_ll : rx_channel_number_cfg);
assign rx_crc_state_init_bit          = (ll_sched_enable ? rx_crc_state_init_bit_ll : rx_crc_state_init_bit_cfg);

assign reg_gpio_axi                   = slv_reg0[15 : 0];

assign tx_gauss_filter_tap_value_axi  = slv_reg1[(GAUSS_FILTER_BIT_WIDTH-1) : 0];
assign tx_gauss_filter_tap_index_axi  = slv_reg1[16+3 : 16+0];

assign tx_cos_table_write_data_axi    = slv_reg2[(IQ_BIT_WIDTH-1) : 0];
assign tx_cos_table_write_address_axi = slv_reg2[16+(SIN_COS_ADDR_BIT_WIDTH-1) : 16+0];

assign tx_sin_table_write_data_axi    = slv_reg3[(IQ_BIT_WIDTH-1) : 0];
assign tx_sin_table_write_address_axi = slv_reg3[16+(SIN_COS_ADDR_BIT_WIDTH-1) : 16+0];

assign tx_preamble_axi                = slv_reg4[(8-1) : 0];

assign tx_access_address_axi          = slv_reg5[(32-1) : 0];
assign tx_crc_state_init_bit_axi      = slv_reg6[(CRC_STATE_BIT_WIDTH-1) : 0];
assign tx_channel_number_axi          = slv_reg7[(CHANNEL_NUMBER_BIT_WIDTH-1) : 0];

assign tx_pdu_octet_mem_data_cfg      = slv_reg8[(8-1) : 0];
assign tx_pdu_octet_mem_addr_cfg      = slv_reg8[(16+NUM_BIT_PAYLOAD_LENGTH)  : 16+0];  // 1 more addr bit is needed: the octet_valid actually will output 2 bytes header, payload length, 3 bytes CRC

assign tx_start_axi                   = slv_reg9[0];

assign rx_unique_bit_sequence_axi     = slv_reg10[(LEN_UNIQUE_BIT_SEQUENCE-1) : 0];
assign rx_channel_number_axi          = slv_reg11[(CHANNEL_NUMBER_BIT_WIDTH-1) : 0];
assign rx_crc_state_init_bit_axi      = slv_reg12[(CRC_STATE_BIT_WIDTH-1) : 0];

// assign rx_pdu_octet_mem_addr          = slv_reg13[5 : 0];

assign data_frame                     = slv_reg47[(FRAME_WD-1) : 0];
assign frame_en                       = slv_reg47[FRAME_WD];

assign slv_reg48 = {31'd0, tx_iq_valid_last_axi};
assign slv_reg49 = {12'd0, rx_hit_flag_axi, rx_decode_run_axi, rx_decode_end_axi, rx_crc_ok_axi_lock, 
                    rx_payload_length_axi_lock, rx_pdu_octet_mem_data};

// assign slv_reg40 = timestamp_rx_hit_flag_axi[(C_S00_AXI_DATA_WIDTH-1) : 0];
// assign slv_reg41 = timestamp_rx_hit_flag_axi[(2*C_S00_AXI_DATA_WIDTH-1) : C_S00_AXI_DATA_WIDTH];
// assign slv_reg42 = timestamp_rx_decode_end_axi[(C_S00_AXI_DATA_WIDTH-1) : 0];
// assign slv_reg43 = timestamp_rx_decode_end_axi[(2*C_S00_AXI_DATA_WIDTH-1) : C_S00_AXI_DATA_WIDTH];

assign slv_reg50 = event0_counter_axi;
assign slv_reg51 = event1_counter_axi;
assign slv_reg52 = event2_counter_axi;
assign slv_reg53 = event3_counter_axi;
assign slv_reg54 = event4_counter_axi;
assign slv_reg55 = event5_counter_axi;

assign slv_reg56 = timestamp_rx_hit_flag_lock_by_decode_end_axi[(C_S00_AXI_DATA_WIDTH-1) : 0];
assign slv_reg57 = timestamp_rx_hit_flag_lock_by_decode_end_axi[(2*C_S00_AXI_DATA_WIDTH-1) : C_S00_AXI_DATA_WIDTH];

assign slv_reg58 = ref_1pps_flip_and_count;
assign slv_reg59 = {ll_pending_ctrl_terminate,
                    ll_pending_ctrl_ch_map,
                    ll_pending_ctrl_feature,
                    ll_pending_ctrl_version,
                    ll_pending_scan_rsp,
                    ll_pending_scan_req,
                    ll_tx_after_ifs_pending,
                    ll_tx_pkt_kind,
                    connection_established,
                    scan_window_open,
                    ll_tifs_counter[10:0],
                    conn_event_counter[7:0]};

assign slv_reg60 = timestamp_axi[(C_S00_AXI_DATA_WIDTH-1) : 0];
assign slv_reg61 = timestamp_axi[(2*C_S00_AXI_DATA_WIDTH-1) : C_S00_AXI_DATA_WIDTH];

assign slv_reg62 = {29'd0, ll_state};

assign slv_reg63 = {15'd0, tx_done, 6'd0, frame_error, rx_done, rx_frame};

// =============ll state machine==========
always @ (posedge axi_aclk) begin
  if (~axi_aresetn) begin
    connection_established_axi_d1 <= 0;
    connection_established_axi_d2 <= 0;
    ll_state <= STANDBY;
  end else begin
    connection_established_axi_d1 <= connection_established;
    connection_established_axi_d2 <= connection_established_axi_d1;

    if (reg_gpio_axi[0] == 0) begin
      ll_state <= STANDBY;
    end else if (connection_established_axi_d2) begin
      ll_state <= CONNECTION;
    end else if (reg_gpio_axi[1]) begin
      ll_state <= SCANNING;
    end else if (reg_gpio_axi[3]) begin
      ll_state <= ADVERTISING;
    end else begin
      ll_state <= STANDBY;
    end
  end
end

// =============enhanced LL scheduler==========
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    adv_interval_cnt <= 0;
    scan_interval_cnt <= 0;
    scan_window_cnt <= 0;
    conn_interval_cnt <= 0;
    supervision_timeout_cnt <= 0;

    adv_channel_seq <= 0;
    scan_window_open <= 0;
    connection_established <= 0;
    tx_pending_empty_pdu <= 0;
    tx_pending_retransmit <= 0;
    phy_2m_active <= 0;

    conn_event_counter <= 0;
    conn_data_channel <= 0;

    last_rx_pdu_byte <= 0;
    last_ctrl_opcode <= 0;
    last_rx_header_byte <= 0;

    tx_start_ll <= 0;
    tx_preamble_ll <= 8'hAA;
    tx_access_address_ll <= 32'h8E89BED6;
    tx_crc_state_init_bit_ll <= 0;
    tx_channel_number_ll <= ADV_CH_37[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
    tx_pdu_octet_mem_addr_ll <= 0;
    rx_unique_bit_sequence_ll <= 32'h8E89BED6;
    rx_channel_number_ll <= ADV_CH_37[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
    rx_crc_state_init_bit_ll <= 0;

    ll_tx_pkt_kind <= LL_PKT_ADV;
    ll_tifs_counter <= 0;
    ll_tx_after_ifs_pending <= 0;
    ll_pending_scan_req <= 0;
    ll_pending_scan_rsp <= 0;
    ll_pending_ctrl_version <= 0;
    ll_pending_ctrl_feature <= 0;
    ll_pending_ctrl_ch_map <= 0;
    ll_pending_ctrl_terminate <= 0;

    tx_mem_addr_advancing <= 0;
    tx_data_sn <= 0;
    tx_data_nesn <= 0;

    conn_channel_map_active <= 37'h1FFFFFFFFF;
    conn_hop_increment_active <= 5'd5;

    rx_pkt_snapshot_toggle_bb_d <= 0;
    rx_pkt_snapshot_pulse_bb <= 0;

    ll_supervision_timeout_pulse <= 0;
    ll_ctrl_pdu_seen_pulse <= 0;
    ll_connect_ind_pulse <= 0;
    ll_phy_update_pulse <= 0;
  end else begin
    tx_start_ll <= 0;
    ll_supervision_timeout_pulse <= 0;
    ll_ctrl_pdu_seen_pulse <= 0;
    ll_connect_ind_pulse <= 0;
    ll_phy_update_pulse <= 0;
    rx_pkt_snapshot_pulse_bb <= 0;

    if (rx_pkt_snapshot_toggle_bb_d != rx_pkt_snapshot_toggle_bb) begin
      rx_pkt_snapshot_toggle_bb_d <= rx_pkt_snapshot_toggle_bb;
      rx_pkt_snapshot_pulse_bb <= 1;
    end

    tx_preamble_ll <= tx_preamble_cfg;
    tx_crc_state_init_bit_ll <= tx_crc_state_init_bit_cfg;
    rx_crc_state_init_bit_ll <= rx_crc_state_init_bit_cfg;

    if (ll_sched_enable == 0) begin
      adv_interval_cnt <= 0;
      scan_interval_cnt <= 0;
      scan_window_cnt <= 0;
      conn_interval_cnt <= 0;
      supervision_timeout_cnt <= 0;
      adv_channel_seq <= 0;
      scan_window_open <= 0;
      connection_established <= 0;
      tx_pending_empty_pdu <= 0;
      tx_pending_retransmit <= 0;
      phy_2m_active <= 0;
      conn_event_counter <= 0;
      conn_data_channel <= 0;
      last_rx_pdu_byte <= 0;
      last_ctrl_opcode <= 0;
      last_rx_header_byte <= 0;
      tx_access_address_ll <= tx_access_address_cfg;
      tx_channel_number_ll <= tx_channel_number_cfg;
      tx_pdu_octet_mem_addr_ll <= 0;
      rx_unique_bit_sequence_ll <= rx_unique_bit_sequence_cfg;
      rx_channel_number_ll <= rx_channel_number_cfg;
      ll_tx_pkt_kind <= LL_PKT_ADV;
      ll_tifs_counter <= 0;
      ll_tx_after_ifs_pending <= 0;
      ll_pending_scan_req <= 0;
      ll_pending_scan_rsp <= 0;
      ll_pending_ctrl_version <= 0;
      ll_pending_ctrl_feature <= 0;
      ll_pending_ctrl_ch_map <= 0;
      ll_pending_ctrl_terminate <= 0;

      tx_mem_addr_advancing <= 0;
      tx_data_sn <= 0;
      tx_data_nesn <= 0;

      conn_channel_map_active <= channel_map_cfg;
      conn_hop_increment_active <= hop_increment_cfg;
    end else begin
      if (tx_mem_addr_advancing) begin
        tx_pdu_octet_mem_addr_ll <= tx_pdu_octet_mem_addr_ll + 1;
      end

      if (ll_tx_after_ifs_pending) begin
        if (ll_tifs_counter == 0) begin
          tx_start_ll <= 1;
          tx_pdu_octet_mem_addr_ll <= 0;
          tx_mem_addr_advancing <= 1;
          ll_tx_after_ifs_pending <= 0;
        end else begin
          ll_tifs_counter <= ll_tifs_counter - 1;
        end
      end

      tx_access_address_ll <= (connection_established ? conn_access_address_cfg : 32'h8E89BED6);
      rx_unique_bit_sequence_ll <= (connection_established ? conn_access_address_cfg : 32'h8E89BED6);

      if (ll_scan_enable) begin
        if (scan_interval_cnt == 0) begin
          scan_window_open <= 1;
          scan_window_cnt <= scan_window_ticks_cfg;
          scan_interval_cnt <= scan_interval_ticks_cfg;
        end else begin
          scan_interval_cnt <= scan_interval_cnt - 1;
        end

        if (scan_window_open) begin
          if (scan_window_cnt == 0)
            scan_window_open <= 0;
          else
            scan_window_cnt <= scan_window_cnt - 1;
        end
      end else begin
        scan_window_open <= 0;
        scan_interval_cnt <= 0;
        scan_window_cnt <= 0;
      end

      if (ll_adv_enable && !connection_established) begin
        if (adv_interval_cnt == 0) begin
          ll_tx_pkt_kind <= LL_PKT_ADV;
          tx_start_ll <= 1;
          tx_pdu_octet_mem_addr_ll <= 0;
          tx_mem_addr_advancing <= 1;
          case (adv_channel_seq)
            2'd0: begin
              tx_channel_number_ll <= ADV_CH_37[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
              rx_channel_number_ll <= ADV_CH_37[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
            end
            2'd1: begin
              tx_channel_number_ll <= ADV_CH_38[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
              rx_channel_number_ll <= ADV_CH_38[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
            end
            default: begin
              tx_channel_number_ll <= ADV_CH_39[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
              rx_channel_number_ll <= ADV_CH_39[(CHANNEL_NUMBER_BIT_WIDTH-1):0];
            end
          endcase

          if (adv_channel_seq == 2'd2)
            adv_channel_seq <= 0;
          else
            adv_channel_seq <= adv_channel_seq + 1;

          adv_interval_cnt <= adv_interval_ticks_cfg;
        end else begin
          adv_interval_cnt <= adv_interval_cnt - 1;
        end
      end else begin
        adv_interval_cnt <= 0;
      end

      if (rx_pkt_snapshot_pulse_bb) begin
        last_rx_header_byte <= rx_pkt_header0_bb;
        last_rx_pdu_byte <= rx_pkt_header1_bb;

        if (connection_established) begin
          supervision_timeout_cnt <= supervision_timeout_ticks_cfg;
          if (rx_crc_ok_axi_lock_bb) begin
            tx_pending_retransmit <= 0;

            if (rx_pkt_header0_bb[3] == tx_data_nesn)
              tx_data_nesn <= ~tx_data_nesn;
            if (rx_pkt_header0_bb[2] == tx_data_sn)
              tx_data_sn <= ~tx_data_sn;
          end else begin
            tx_pending_retransmit <= 1;
          end

          if (rx_pkt_header0_bb[1:0] == 2'b11) begin
            ll_ctrl_pdu_seen_pulse <= 1;
            last_ctrl_opcode <= rx_pkt_ctrl_opcode_bb;

            if (rx_pkt_ctrl_opcode_bb == LL_CTRL_VERSION_IND)
              ll_pending_ctrl_version <= 1;
            if ((rx_pkt_ctrl_opcode_bb == LL_CTRL_FEATURE_REQ) || (rx_pkt_ctrl_opcode_bb == LL_CTRL_FEATURE_RSP))
              ll_pending_ctrl_feature <= 1;
            if (rx_pkt_ctrl_opcode_bb == LL_CTRL_CHANNEL_MAP_IND)
              ll_pending_ctrl_ch_map <= 1;
            if (rx_pkt_ctrl_opcode_bb == LL_CTRL_TERMINATE_IND)
              ll_pending_ctrl_terminate <= 1;
          end
        end else if (ll_scan_enable && scan_window_open && rx_crc_ok_axi_lock_bb) begin
          // CONNECT_IND hook from ADV channel PDU type field.
          if ((rx_pkt_header0_bb[3:0] == 4'h5) && (rx_pkt_header1_bb[5:0] >= 6'd34)) begin
            ll_connect_ind_pulse <= 1;
            connection_established <= ll_conn_enable;
            conn_event_counter <= 0;
            conn_data_channel <= 0;
            conn_interval_cnt <= conn_interval_ticks_cfg;
            supervision_timeout_cnt <= supervision_timeout_ticks_cfg;

            tx_access_address_ll <= (rx_pkt_conn_aa_bb == 0 ? conn_access_address_cfg : rx_pkt_conn_aa_bb);
            rx_unique_bit_sequence_ll <= (rx_pkt_conn_aa_bb == 0 ? conn_access_address_cfg : rx_pkt_conn_aa_bb);
            tx_crc_state_init_bit_ll <= (rx_pkt_conn_crc_init_bb == 0 ? conn_crc_init_cfg : rx_pkt_conn_crc_init_bb);
            rx_crc_state_init_bit_ll <= (rx_pkt_conn_crc_init_bb == 0 ? conn_crc_init_cfg : rx_pkt_conn_crc_init_bb);
            conn_channel_map_active <= (|rx_pkt_conn_ch_map_bb ? rx_pkt_conn_ch_map_bb : channel_map_cfg);
            conn_hop_increment_active <= (rx_pkt_conn_hop_inc_bb == 0 ? hop_increment_cfg : rx_pkt_conn_hop_inc_bb);

            tx_data_sn <= 0;
            tx_data_nesn <= 0;
            tx_channel_number_ll <= 0;
            rx_channel_number_ll <= 0;
          end else if (ll_scan_active && ((rx_pkt_header0_bb[3:0] == 4'h0) || (rx_pkt_header0_bb[3:0] == 4'h6))) begin
            // Active scanning hook for SCAN_REQ scheduling.
            ll_pending_scan_req <= 1;
            ll_tx_pkt_kind <= LL_PKT_SCAN_REQ;
            ll_tifs_counter <= tifs_ticks_cfg;
            ll_tx_after_ifs_pending <= 1;
          end else if (ll_adv_enable && (rx_pkt_header0_bb[3:0] == 4'h3)) begin
            ll_pending_scan_rsp <= 1;
            ll_tx_pkt_kind <= LL_PKT_SCAN_RSP;
            ll_tifs_counter <= tifs_ticks_cfg;
            ll_tx_after_ifs_pending <= 1;
          end
        end
      end

      if (connection_established) begin
        if (ll_phy_2m_req && !phy_2m_active) begin
          // Reserved for future 2M PHY negotiation once PHY-side support is available.
          // ll_phy_update_pulse <= 1;
          // phy_2m_active <= 1;
          ll_phy_update_pulse <= 0;
          phy_2m_active <= 0;
        end

        if (conn_interval_cnt == 0) begin
          tx_start_ll <= 1;
          tx_pdu_octet_mem_addr_ll <= 0;
          tx_mem_addr_advancing <= 1;
          conn_event_counter <= conn_event_counter + 1;
          conn_data_channel <= csa1_next_channel(conn_data_channel, conn_hop_increment_active, conn_channel_map_active);
          tx_channel_number_ll <= csa1_next_channel(conn_data_channel, conn_hop_increment_active, conn_channel_map_active);
          rx_channel_number_ll <= csa1_next_channel(conn_data_channel, conn_hop_increment_active, conn_channel_map_active);
          conn_interval_cnt <= conn_interval_ticks_cfg;

          if (ll_pending_ctrl_terminate) begin
            ll_tx_pkt_kind <= LL_PKT_CTRL_TERM;
            ll_pending_ctrl_terminate <= 0;
          end else if (ll_pending_ctrl_ch_map) begin
            ll_tx_pkt_kind <= LL_PKT_CTRL_CH_MAP;
            ll_pending_ctrl_ch_map <= 0;
          end else if (ll_pending_ctrl_version) begin
            ll_tx_pkt_kind <= LL_PKT_CTRL_VERSION;
            ll_pending_ctrl_version <= 0;
          end else if (ll_pending_ctrl_feature) begin
            ll_tx_pkt_kind <= LL_PKT_CTRL_FEATURE;
            ll_pending_ctrl_feature <= 0;
          end else begin
            ll_tx_pkt_kind <= LL_PKT_DATA_EMPTY;
          end

          if (tx_pending_retransmit)
            tx_pending_empty_pdu <= 0;
          else
            tx_pending_empty_pdu <= 1;
        end else begin
          conn_interval_cnt <= conn_interval_cnt - 1;
        end

        if (tx_iq_valid_last)
          supervision_timeout_cnt <= supervision_timeout_ticks_cfg;
        else if (supervision_timeout_cnt == 0) begin
          connection_established <= 0;
          ll_supervision_timeout_pulse <= 1;
          tx_pending_retransmit <= 0;
          tx_pending_empty_pdu <= 0;
          phy_2m_active <= 0;
        end else begin
          supervision_timeout_cnt <= supervision_timeout_cnt - 1;
        end
      end else begin
        conn_interval_cnt <= 0;
        conn_event_counter <= conn_event_counter;
        tx_pending_empty_pdu <= 0;
        tx_pending_retransmit <= 0;
        supervision_timeout_cnt <= 0;
        tx_mem_addr_advancing <= 0;
        if (!ll_scan_enable)
          ll_pending_scan_req <= 0;
        if (!ll_adv_enable)
          ll_pending_scan_rsp <= 0;
      end

      if (tx_iq_valid_last)
        tx_mem_addr_advancing <= 0;
    end
  end
end

// ==========rx PDU and state RAM=============
rx_ram #
(
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .NUM_BIT_PAYLOAD_LENGTH(NUM_BIT_PAYLOAD_LENGTH),
  .RD_DATA_AXI_REG_IDX(40) // MUST be aligned with .rd_data_axi(slv_regXX)
) rx_ram_i (
  .bb_clk(bb_clk),
  .bb_rst(bb_rst),

  .axi_aclk(axi_aclk),
  .axi_aresetn(axi_aresetn),

  .rx_unique_bit_sequence_axi(rx_unique_bit_sequence_axi),
  .rx_channel_number_axi(rx_channel_number_axi),
  .rx_crc_state_init_bit_axi(rx_crc_state_init_bit_axi),

  .rx_hit_flag_axi(rx_hit_flag_axi),
  .rx_decode_run_axi(rx_decode_run_axi),
  .rx_decode_end_axi(rx_decode_end_axi),
  .rx_crc_ok_axi_lock(rx_crc_ok_axi_lock),
  .rx_payload_length_axi_lock(rx_payload_length_axi_lock),

  .rx_pdu_octet_mem_addr(rx_pdu_octet_mem_addr),
  .rx_pdu_octet_mem_data(rx_pdu_octet_mem_data),

  .simulation_en(simulation_en),
  .simulation_rx_ram_read_en(simulation_rx_ram_read_en),

  .slv_reg_rden(slv_reg_rden),
  .axi_araddr_core(axi_araddr_core),
  .slv_reg_wren(slv_reg_wren),
  .axi_awaddr_core(axi_awaddr_core),

  .rd_data_axi(slv_reg40) // MUST be aligned with RD_DATA_AXI_REG_IDX!
);

// =============rx timestamp capture==========
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    timestamp_rx_hit_flag <= 0;
    timestamp_rx_decode_end <= 0;
    timestamp_rx_hit_flag_lock_by_decode_end <= 0;
  end else begin
    if (rx_hit_flag) begin
      timestamp_rx_hit_flag <= timestamp;
    end
    if (rx_decode_end) begin
      timestamp_rx_decode_end <= timestamp;
      timestamp_rx_hit_flag_lock_by_decode_end <= timestamp_rx_hit_flag;
    end
  end
end

// ============lock the payload length and crc result by decode end=========
always @ (posedge axi_aclk) begin
  if (~axi_aresetn) begin
    rx_crc_ok_axi_lock <= 0;
    rx_payload_length_axi_lock <= 0;

    rx_pkt_parse_active_axi <= 0;
    rx_pkt_header0_axi <= 0;
    rx_pkt_header1_axi <= 0;
    rx_pkt_ctrl_opcode_axi <= 0;
    rx_pkt_conn_aa_axi <= 0;
    rx_pkt_conn_crc_init_axi <= 0;
    rx_pkt_conn_ch_map_axi <= 0;
    rx_pkt_conn_hop_inc_axi <= 0;
    rx_pkt_snapshot_toggle_axi <= 0;
  end else begin
    if (rx_decode_end_axi) begin
      rx_crc_ok_axi_lock <= rx_crc_ok_axi;
      rx_payload_length_axi_lock <= rx_payload_length_axi;

      rx_pkt_parse_active_axi <= 1;
      rx_pkt_header0_axi <= 0;
      rx_pkt_header1_axi <= 0;
      rx_pkt_ctrl_opcode_axi <= 0;
      rx_pkt_conn_aa_axi <= 0;
      rx_pkt_conn_crc_init_axi <= 0;
      rx_pkt_conn_ch_map_axi <= 0;
      rx_pkt_conn_hop_inc_axi <= 0;
    end else if (rx_pkt_parse_active_axi) begin
      case (rx_pdu_octet_mem_addr)
        0: rx_pkt_header0_axi <= rx_pdu_octet_mem_data;
        1: rx_pkt_header1_axi <= rx_pdu_octet_mem_data;
        2: rx_pkt_ctrl_opcode_axi <= rx_pdu_octet_mem_data;
        14: rx_pkt_conn_aa_axi[7:0] <= rx_pdu_octet_mem_data;
        15: rx_pkt_conn_aa_axi[15:8] <= rx_pdu_octet_mem_data;
        16: rx_pkt_conn_aa_axi[23:16] <= rx_pdu_octet_mem_data;
        17: rx_pkt_conn_aa_axi[31:24] <= rx_pdu_octet_mem_data;
        18: rx_pkt_conn_crc_init_axi[7:0] <= rx_pdu_octet_mem_data;
        19: rx_pkt_conn_crc_init_axi[15:8] <= rx_pdu_octet_mem_data;
        20: rx_pkt_conn_crc_init_axi[23:16] <= rx_pdu_octet_mem_data;
        30: rx_pkt_conn_ch_map_axi[7:0] <= rx_pdu_octet_mem_data;
        31: rx_pkt_conn_ch_map_axi[15:8] <= rx_pdu_octet_mem_data;
        32: rx_pkt_conn_ch_map_axi[23:16] <= rx_pdu_octet_mem_data;
        33: rx_pkt_conn_ch_map_axi[31:24] <= rx_pdu_octet_mem_data;
        34: rx_pkt_conn_ch_map_axi[36:32] <= rx_pdu_octet_mem_data[4:0];
        35: rx_pkt_conn_hop_inc_axi <= rx_pdu_octet_mem_data[4:0];
        default: begin
        end
      endcase

      if (rx_pdu_octet_mem_addr > (rx_payload_length_axi_lock + 6)) begin
        rx_pkt_parse_active_axi <= 0;
        rx_pkt_snapshot_toggle_axi <= ~rx_pkt_snapshot_toggle_axi;
      end
    end
  end
end

// =============event counters==========
event_counter_pulse # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_rx_hit_flag_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .pulse_signal(rx_hit_flag),

  .count(event0_counter)
);

event_counter_pulse # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_rx_crc_ok_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .pulse_signal(rx_crc_ok),

  .count(event1_counter)
);

event_counter_pulse # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_agc_lock_i (
  .clk(bb_clk),
  .rst(bb_rst),

  .pulse_signal(agc_lock_change&agc_lock_state),

  .count(event2_counter)
);

event_counter_pulse # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_rx_decode_end_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .pulse_signal(rx_decode_end),

  .count(event3_counter)
);

event_counter_pulse # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_supervision_timeout_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .pulse_signal(ll_supervision_timeout_pulse),

  .count(event4_counter)
);

event_counter_level # (
  .COUNTER_WIDTH(C_S00_AXI_DATA_WIDTH)
) event_counter_level_decode_run_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .level_signal(rx_decode_run),

  .count(event5_counter)
);

event_counter_pulse # (
  .COUNTER_WIDTH(2*C_S00_AXI_DATA_WIDTH)
) event_counter_pulse_timestamp_i (
  .clk(bb_clk),
  .rst(bb_rst|reg_gpio[15]),

  .pulse_signal(1'd1),

  .count(timestamp)
);

// =============1pps counter==========
always @ (posedge axi_aclk) begin
  if (~axi_aresetn) begin
    ref_1pps_counter <= 0;
    ref_1pps_flip_and_count <= 0;
    ref_1pps_delay1 <= 0;
    ref_1pps_delay2 <= 0;
    ref_1pps_delay3 <= 0;
  end else begin
    ref_1pps_delay1 <= ref_1pps;
    ref_1pps_delay2 <= ref_1pps_delay1;
    ref_1pps_delay3 <= ref_1pps_delay2;

    if ((ref_1pps_delay3 == 1) && (ref_1pps_delay2 == 0)) begin
      ref_1pps_counter <= 0;
      ref_1pps_flip_and_count[(C_S00_AXI_DATA_WIDTH-2) : 0] <= ref_1pps_counter;
      ref_1pps_flip_and_count[C_S00_AXI_DATA_WIDTH-1]       <= (~ref_1pps_flip_and_count[C_S00_AXI_DATA_WIDTH-1]);
    end else begin
      ref_1pps_counter <= ref_1pps_counter + 1;
    end
  end
end

// =============s axi clk and bb clk conversion==========
clk_cross_bus #
(
  .DATA_WIDTH(16+
              4+
              GAUSS_FILTER_BIT_WIDTH+
              SIN_COS_ADDR_BIT_WIDTH+
              IQ_BIT_WIDTH+
              SIN_COS_ADDR_BIT_WIDTH+
              IQ_BIT_WIDTH+
              8+
              32+
              CRC_STATE_BIT_WIDTH+
              CHANNEL_NUMBER_BIT_WIDTH+
              1+
              LEN_UNIQUE_BIT_SEQUENCE+
              CHANNEL_NUMBER_BIT_WIDTH+
              CRC_STATE_BIT_WIDTH+
              32+
              1+
              6+
              8+
              8+
              8+
              32+
              24+
              37+
              5+
              1+
              1)
) clk_cross_bus_s_axi_to_bb_i (
  .write_clk(axi_aclk),
  .rst(~axi_aresetn),

  .write_data({reg_gpio_axi,
               tx_gauss_filter_tap_index_axi, 
               tx_gauss_filter_tap_value_axi, 
               tx_cos_table_write_address_axi, 
               tx_cos_table_write_data_axi, 
               tx_sin_table_write_address_axi, 
               tx_sin_table_write_data_axi,
               tx_preamble_axi,
               tx_access_address_axi, 
               tx_crc_state_init_bit_axi, 
               tx_channel_number_axi,
               tx_start_axi,
               rx_unique_bit_sequence_axi, 
               rx_channel_number_axi, 
               rx_crc_state_init_bit_axi,
               slv_reg39,
               slv_reg_rden,
               axi_araddr_core,
               rx_pkt_header0_axi,
               rx_pkt_header1_axi,
               rx_pkt_ctrl_opcode_axi,
               rx_pkt_conn_aa_axi,
               rx_pkt_conn_crc_init_axi,
               rx_pkt_conn_ch_map_axi,
               rx_pkt_conn_hop_inc_axi,
               rx_pkt_snapshot_toggle_axi,
               rx_crc_ok_axi_lock}),

  .read_clk(bb_clk),
  .read_data({reg_gpio,
              tx_gauss_filter_tap_index_cfg,
              tx_gauss_filter_tap_value_cfg,
              tx_cos_table_write_address_cfg,
              tx_cos_table_write_data_cfg,
              tx_sin_table_write_address_cfg,
              tx_sin_table_write_data_cfg,
              tx_preamble_cfg,
              tx_access_address_cfg,
              tx_crc_state_init_bit_cfg,
              tx_channel_number_cfg,
              tx_start_cfg,
              rx_unique_bit_sequence_cfg,
              rx_channel_number_cfg,
              rx_crc_state_init_bit_cfg,
              slv_reg39_bb,
              slv_reg_rden_bb,
              axi_araddr_core_bb,
              rx_pkt_header0_bb,
              rx_pkt_header1_bb,
              rx_pkt_ctrl_opcode_bb,
              rx_pkt_conn_aa_bb,
              rx_pkt_conn_crc_init_bb,
              rx_pkt_conn_ch_map_bb,
              rx_pkt_conn_hop_inc_bb,
              rx_pkt_snapshot_toggle_bb,
              rx_crc_ok_axi_lock_bb})
);

clk_cross_bus #
(
  .DATA_WIDTH(C_S00_AXI_DATA_WIDTH+
              C_S00_AXI_DATA_WIDTH+
              C_S00_AXI_DATA_WIDTH+
              C_S00_AXI_DATA_WIDTH+
              C_S00_AXI_DATA_WIDTH+
              C_S00_AXI_DATA_WIDTH+
              (2*C_S00_AXI_DATA_WIDTH)+
              (2*C_S00_AXI_DATA_WIDTH)+
              (2*C_S00_AXI_DATA_WIDTH)+
              (2*C_S00_AXI_DATA_WIDTH)+
              1+
              1+
              1+
              1+
              1+
              NUM_BIT_PAYLOAD_LENGTH)
) clk_cross_bus_bb_to_s_axi_i (
  .write_clk(bb_clk),
  .rst(bb_rst),

  .write_data({event0_counter,
               event1_counter,
               event2_counter,
               event3_counter,
               event4_counter,
               event5_counter,
               timestamp_rx_hit_flag_lock_by_decode_end,
               timestamp_rx_hit_flag,
               timestamp_rx_decode_end,
               timestamp,
               tx_iq_valid_last, 
               rx_hit_flag,
               rx_decode_run,
               rx_decode_end,
               rx_crc_ok,
               rx_payload_length}),

  .read_clk(axi_aclk),
  .read_data({event0_counter_axi,
              event1_counter_axi,
              event2_counter_axi,
              event3_counter_axi,
              event4_counter_axi,
              event5_counter_axi,
              timestamp_rx_hit_flag_lock_by_decode_end_axi,
              timestamp_rx_hit_flag_axi,
              timestamp_rx_decode_end_axi,
              timestamp_axi,
              tx_iq_valid_last_axi, 
              rx_hit_flag_axi,
              rx_decode_run_axi,
              rx_decode_end_axi,
              rx_crc_ok_axi,
              rx_payload_length_axi})
);

// -----------------------------debug-----------------------------
// `KEEP_FOR_DBG reg  [14:0] rx_decode_run_counter;
// `KEEP_FOR_DBG wire [14:0] rx_decode_run_counter_copy;
// assign rx_decode_run_counter_copy = rx_decode_run_counter;
// always @ (posedge bb_clk) begin
//   if (rx_decode_run == 0) begin
//     rx_decode_run_counter <= 0;
//   end else begin
//     rx_decode_run_counter <= rx_decode_run_counter + 1;
//   end
// end

// `KEEP_FOR_DBG reg  [RF_I_OR_Q_BIT_WIDTH : 0] i_abs_add_q_abs_threshold;
// `KEEP_FOR_DBG reg  [RF_I_OR_Q_BIT_WIDTH : 0] i_abs_add_q_abs_threshold_realtime;
// `KEEP_FOR_DBG reg  rx_abs_high;
// `KEEP_FOR_DBG reg  [14:0] rx_abs_high_delay;
// `KEEP_FOR_DBG wire rx_abs_high_wide;
// `KEEP_FOR_DBG reg  rx_abs_high_wide_delay;
// `KEEP_FOR_DBG wire rx_abs_high_wide_falling_edge;
// `KEEP_FOR_DBG reg  search_rx_end_state;
// `KEEP_FOR_DBG reg  decode_end_never_happen;
// `KEEP_FOR_DBG reg  rx_decode_end_lock;

// assign rx_abs_high_wide = (|rx_abs_high_delay);
// assign rx_abs_high_wide_falling_edge = ( (rx_abs_high_wide_delay == 1) && (rx_abs_high_wide == 0) ) ? 1'b1 : 1'b0;

// always @* begin
//   case (slv_reg39_bb[2:0])
//     3'd0 : begin 
//       i_abs_add_q_abs_threshold_realtime <= i_abs_add_q_abs;
//       end
//     3'd1 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {1'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:1]};
//       end
//     3'd2 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {2'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:2]};
//       end
//     3'd3 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {3'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:3]};
//       end
//     3'd4 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {4'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:4]};
//       end
//     3'd5 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {5'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:5]};
//       end
//     3'd6 : begin 
//       i_abs_add_q_abs_threshold_realtime <= {6'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:6]};
//       end
//     3'd7 : begin
//       i_abs_add_q_abs_threshold_realtime <= {7'd0, i_abs_add_q_abs[RF_I_OR_Q_BIT_WIDTH:7]};
//       end
//   endcase
// end

// always @ (posedge bb_clk) begin
//   if (bb_rst) begin
//     i_abs_add_q_abs_threshold <= 0;
//     rx_abs_high <= 0;

//     rx_abs_high_delay <= 0;
//     rx_abs_high_wide_delay <= 0;

//     search_rx_end_state <= 0;
//     decode_end_never_happen <= 0;
//     rx_decode_end_lock <= 0;
//   end else begin
//     rx_abs_high_delay[0]  <= rx_abs_high;
//     rx_abs_high_delay[14:1]  <= rx_abs_high_delay[13:0];

//     rx_abs_high_wide_delay <= rx_abs_high_wide;

//     case (search_rx_end_state)
//       0: begin
//         rx_abs_high <= 0;
//         decode_end_never_happen <= 0;
//         rx_decode_end_lock <= 0;

//         if (rx_hit_flag) begin
//           i_abs_add_q_abs_threshold <= i_abs_add_q_abs_threshold_realtime;

//           search_rx_end_state <= 1;
//         end else begin
//           i_abs_add_q_abs_threshold <= i_abs_add_q_abs_threshold;

//           search_rx_end_state <= search_rx_end_state;
//         end
//       end
//       1: begin
//         i_abs_add_q_abs_threshold <= i_abs_add_q_abs_threshold;

//         rx_abs_high <= (i_abs_add_q_abs > i_abs_add_q_abs_threshold) ? 1'b1 : 1'b0;

//         if (rx_decode_end) begin 
//           rx_decode_end_lock <= 1;
//         end
        
//         if ( rx_abs_high_wide_falling_edge ) begin
//           if (rx_decode_end_lock == 0) begin
//             decode_end_never_happen <= 1;
//           end

//           search_rx_end_state <= 0;
//         end
//       end
//     endcase
//   end
// end

// `KEEP_FOR_DBG reg  [24:0] inter_frame_spacing_counter;
// `KEEP_FOR_DBG reg  [24:0] inter_frame_spacing_counter_lock;
// always @ (posedge bb_clk) begin
//   if (bb_rst) begin
//     inter_frame_spacing_counter_lock <= 25'h1FFFFFF;
//     inter_frame_spacing_counter <= 0;
//   end else begin
//     if (rx_decode_end) begin
//       inter_frame_spacing_counter <= 0;
//     end else if (rx_hit_flag) begin
//       inter_frame_spacing_counter_lock <= inter_frame_spacing_counter;
//     end else begin
//       inter_frame_spacing_counter <= inter_frame_spacing_counter + 1;
//     end
//   end
// end

`KEEP_FOR_DBG reg  [25:0] decode_end_to_host_read_counter;
`KEEP_FOR_DBG reg  [25:0] decode_end_to_host_read_counter_max;
assign slv_reg41 = decode_end_to_host_read_counter;
always @ (posedge axi_aclk) begin
  if ((~axi_aresetn) | reg_gpio[15]) begin
    decode_end_to_host_read_counter_max <= 0;
    decode_end_to_host_read_counter <= 0;
  end else begin
    decode_end_to_host_read_counter <= (event0_counter_axi != 0? (rx_decode_end_axi? 0 : (decode_end_to_host_read_counter + 1)) : decode_end_to_host_read_counter);

    if (slv_reg_rden && axi_araddr_core == 41) begin
      decode_end_to_host_read_counter_max <= (decode_end_to_host_read_counter > decode_end_to_host_read_counter_max ? decode_end_to_host_read_counter : decode_end_to_host_read_counter_max);
    end
  end
end

assign event0_event5_unequal = (event0_counter_delay1 != event5_counter); // for debug
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    event0_counter_delay1 <= 0;
    event0_counter_delay2 <= 0;
    event0_counter_delay3 <= 0;
  end else begin
    event0_counter_delay1 <= event0_counter; // for debug
    event0_counter_delay2 <= event0_counter_delay1; // for debug
    event0_counter_delay3 <= event0_counter_delay2; // for debug
  end
end
// -----------------------------debug-----------------------------

ll_s_axi # ( 
  .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) ll_s_axi_i (
  .S_AXI_ACLK(axi_aclk),
  .S_AXI_ARESETN(axi_aresetn),
  .S_AXI_AWADDR(axi_awaddr),
  .S_AXI_AWPROT(axi_awprot),
  .S_AXI_AWVALID(axi_awvalid),
  .S_AXI_AWREADY(axi_awready),
  .S_AXI_WDATA(axi_wdata),
  .S_AXI_WSTRB(axi_wstrb),
  .S_AXI_WVALID(axi_wvalid),
  .S_AXI_WREADY(axi_wready),
  .S_AXI_BRESP(axi_bresp),
  .S_AXI_BVALID(axi_bvalid),
  .S_AXI_BREADY(axi_bready),
  .S_AXI_ARADDR(axi_araddr),
  .S_AXI_ARPROT(axi_arprot),
  .S_AXI_ARVALID(axi_arvalid),
  .S_AXI_ARREADY(axi_arready),
  .S_AXI_RDATA(axi_rdata),
  .S_AXI_RRESP(axi_rresp),
  .S_AXI_RVALID(axi_rvalid),
  .S_AXI_RREADY(axi_rready),

  .slv_reg_rden(slv_reg_rden),
  .axi_araddr_core(axi_araddr_core),
  .slv_reg_wren_signal(slv_reg_wren),
  .axi_awaddr_core(axi_awaddr_core),

  // from reg0 to 47 for writing to PL
  .SLV_REG0(slv_reg0),
  .SLV_REG1(slv_reg1),
  .SLV_REG2(slv_reg2),
  .SLV_REG3(slv_reg3),
  .SLV_REG4(slv_reg4),
  .SLV_REG5(slv_reg5),
  .SLV_REG6(slv_reg6),
  .SLV_REG7(slv_reg7),
  .SLV_REG8(slv_reg8),
  .SLV_REG9(slv_reg9),
  .SLV_REG10(slv_reg10),
  .SLV_REG11(slv_reg11),
  .SLV_REG12(slv_reg12),
  .SLV_REG13(slv_reg13),
  .SLV_REG14(slv_reg14),
  .SLV_REG15(slv_reg15),
  .SLV_REG16(slv_reg16),
  .SLV_REG17(slv_reg17),
  .SLV_REG18(slv_reg18),
  .SLV_REG19(slv_reg19),
  .SLV_REG20(slv_reg20),
  .SLV_REG21(slv_reg21),
  .SLV_REG22(slv_reg22),
  .SLV_REG23(slv_reg23),
  .SLV_REG24(slv_reg24),
  .SLV_REG25(slv_reg25),
  .SLV_REG26(slv_reg26),
  .SLV_REG27(slv_reg27),
  .SLV_REG28(slv_reg28),
  .SLV_REG29(slv_reg29),
  .SLV_REG30(slv_reg30),
  .SLV_REG31(slv_reg31),
  .SLV_REG32(slv_reg32),
  .SLV_REG33(slv_reg33),
  .SLV_REG34(slv_reg34),
  .SLV_REG35(slv_reg35),
  .SLV_REG36(slv_reg36),
  .SLV_REG37(slv_reg37),
  .SLV_REG38(slv_reg38),
  .SLV_REG39(slv_reg39),
  // from reg40 for reading from PL
  .SLV_REG40(slv_reg40),
  .SLV_REG41(slv_reg41),
  .SLV_REG42(slv_reg42),
  .SLV_REG43(slv_reg43),
  .SLV_REG44(slv_reg44),
  .SLV_REG45(slv_reg45),
  .SLV_REG46(slv_reg46),
  .SLV_REG47(slv_reg47),
  .SLV_REG48(slv_reg48),
  .SLV_REG49(slv_reg49),
  .SLV_REG50(slv_reg50),
  .SLV_REG51(slv_reg51),
  .SLV_REG52(slv_reg52),
  .SLV_REG53(slv_reg53),
  .SLV_REG54(slv_reg54),
  .SLV_REG55(slv_reg55),
  .SLV_REG56(slv_reg56),
  .SLV_REG57(slv_reg57),
  .SLV_REG58(slv_reg58),
  .SLV_REG59(slv_reg59),
  .SLV_REG60(slv_reg60),
  .SLV_REG61(slv_reg61),
  .SLV_REG62(slv_reg62),
  .SLV_REG63(slv_reg63)
);

uart_frame_tx #(
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD)
) uart_frame_tx_i (
  .clk(axi_aclk),
  .rst_n(axi_aresetn),
  .frame_en(frame_en),
  .data_frame(data_frame),
  .tx_done(tx_done),
  .uart_tx(uart_tx)
);

uart_frame_rx #(
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD)
) uart_frame_rx_i (
  .clk(axi_aclk),
  .rst_n(axi_aresetn),
  .uart_rx(uart_rx),
  .rx_frame(rx_frame),
  .rx_done(rx_done),
  .frame_error(frame_error)
);

endmodule

// ======================sub modules==========================================
module rx_ram #
(
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter C_S00_AXI_DATA_WIDTH  = 32,
  parameter NUM_BIT_PAYLOAD_LENGTH = 8, // 8 bit in the core spec 6.2
  parameter RD_DATA_AXI_REG_IDX = 40
) (
  input wire bb_clk,
  input wire bb_rst,

  input wire axi_aclk,
  input wire axi_aresetn,

  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1)  : 0] rx_unique_bit_sequence_axi,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number_axi,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit_axi,

  `KEEP_FOR_DBG input wire rx_hit_flag_axi,
  `KEEP_FOR_DBG input wire rx_decode_run_axi,
  `KEEP_FOR_DBG input wire rx_decode_end_axi,
  `KEEP_FOR_DBG input wire rx_crc_ok_axi_lock,
  `KEEP_FOR_DBG input wire [(NUM_BIT_PAYLOAD_LENGTH-1):0] rx_payload_length_axi_lock,

  `KEEP_FOR_DBG output reg  [NUM_BIT_PAYLOAD_LENGTH:0] rx_pdu_octet_mem_addr,  // 1 more addr bit is needed: the octet_valid actually will output 2 bytes header, payload length, 3 bytes CRC
  `KEEP_FOR_DBG input  wire [7:0] rx_pdu_octet_mem_data,

  `KEEP_FOR_DBG input  wire simulation_en,
  `KEEP_FOR_DBG input  wire simulation_rx_ram_read_en,

  `KEEP_FOR_DBG input  wire slv_reg_rden,
  `KEEP_FOR_DBG input  wire [5:0] axi_araddr_core,
  `KEEP_FOR_DBG input  wire slv_reg_wren,
  `KEEP_FOR_DBG input  wire [5:0] axi_awaddr_core,

  `KEEP_FOR_DBG output wire [(C_S00_AXI_DATA_WIDTH-1):0] rd_data_axi
);
localparam ADDR_WIDTH_DPRAM = NUM_BIT_PAYLOAD_LENGTH+1;

`KEEP_FOR_DBG reg  [(ADDR_WIDTH_DPRAM-1) : 0] write_address;
`KEEP_FOR_DBG reg  [(ADDR_WIDTH_DPRAM-1) : 0] read_address;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] write_data;
`KEEP_FOR_DBG wire write_enable;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1) : 0] read_data;

`KEEP_FOR_DBG wire word_out_strobe;
`KEEP_FOR_DBG wire [(C_S00_AXI_DATA_WIDTH-1):0] word_out;

`KEEP_FOR_DBG reg reading_state;
`KEEP_FOR_DBG reg [7 : 0] octet_out;
`KEEP_FOR_DBG reg [(ADDR_WIDTH_DPRAM-1) : 0] octet_count;
`KEEP_FOR_DBG reg octet_strobe;

`KEEP_FOR_DBG reg [(ADDR_WIDTH_DPRAM-1) : 0] octet_count_tmp_delay1;
`KEEP_FOR_DBG reg [(ADDR_WIDTH_DPRAM-1) : 0] octet_count_tmp_delay2;
`KEEP_FOR_DBG reg octet_strobe_tmp_delay1;

`KEEP_FOR_DBG wire rd_en_axi;
`KEEP_FOR_DBG wire reset_rd_addr_axi;

`KEEP_FOR_DBG wire [(ADDR_WIDTH_DPRAM-1) : 0] header_payload_crc_len;

assign write_data = word_out;
assign write_enable = word_out_strobe;
assign header_payload_crc_len = 2 + rx_payload_length_axi_lock + 3; // 2 bytes header, payload length, 3 bytes CRC

// 5'd40 means slv_reg40 read signal
assign rd_en_axi = ( simulation_en? simulation_rx_ram_read_en : (slv_reg_rden && axi_araddr_core == RD_DATA_AXI_REG_IDX) );
assign reset_rd_addr_axi = (slv_reg_wren && axi_awaddr_core == RD_DATA_AXI_REG_IDX);

// process to generate octet & strobe & octet count, etc.
always @ (posedge axi_aclk) begin
  if (~axi_aresetn) begin
    rx_pdu_octet_mem_addr <= 0;
    reading_state <= 0;

    octet_out <= 0;
    octet_strobe <= 0;
    octet_count <= 0;

    octet_count_tmp_delay1  <= 0;
    octet_count_tmp_delay2  <= 0;
    octet_strobe_tmp_delay1 <= 0;
  end else begin
    octet_count_tmp_delay2 <= octet_count_tmp_delay1;

    octet_strobe <= octet_strobe_tmp_delay1;
    octet_count <= octet_count_tmp_delay2;

    case (reading_state)
      0: begin
        if (rx_decode_end_axi) begin
          rx_pdu_octet_mem_addr <= 0;
          octet_out <= 0;
          octet_count_tmp_delay1 <= 0;
          reading_state <= 1;
        end
      end
      1: begin
        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;
        if (rx_pdu_octet_mem_addr <= header_payload_crc_len) begin
          octet_out <= rx_pdu_octet_mem_data;
          octet_strobe_tmp_delay1 <= (rx_pdu_octet_mem_addr == header_payload_crc_len? 0 : 1);
          octet_count_tmp_delay1 <= octet_count_tmp_delay1 + 1;
        end else if (rx_pdu_octet_mem_addr <= (header_payload_crc_len + 4) ) begin
          octet_strobe_tmp_delay1 <= 0;
        end else begin
          reading_state <= 0;
        end
      end
    endcase
  end
end

octet_to_word #
(
  .NUM_OCTET_TOTAL_BITWIDTH(ADDR_WIDTH_DPRAM),
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
) octet_to_word_for_rx_ram_i (
  .clk(axi_aclk),
  .rstn(axi_aresetn&reading_state),

  .octet_in(octet_out),
  .octet_in_strobe(octet_strobe),
  .octet_count(octet_count),
  .num_octet_total(header_payload_crc_len),

  .word_out(word_out),
  .word_out_strobe(word_out_strobe)
);

// process to write to dpram
always @ (posedge axi_aclk) begin
  if ( (~axi_aresetn) || (reading_state == 0) ) begin
    write_address <= 0;
  end else begin
    if (word_out_strobe) begin
      write_address <= write_address + 1;
    end
  end
end

// process to read from dpram
always @ (posedge axi_aclk) begin
  if ( (~axi_aresetn) || reset_rd_addr_axi ) begin
    read_address <= 0;
  end else begin
    if (rd_en_axi) begin
      read_address <= read_address + 1;
    end
  end
end

sdpram_one_clk #
(
  .DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .ADDRESS_WIDTH(ADDR_WIDTH_DPRAM)
) sdpram_one_clk_for_rx_ram_i (
  .clk(axi_aclk),
  .rst(~axi_aresetn),

  .write_address(write_address),
  .write_data(write_data),
  .write_enable(write_enable),

  .read_address(read_address),
  .read_data(rd_data_axi)
);

endmodule

module octet_to_word #
(
  parameter NUM_OCTET_TOTAL_BITWIDTH = 7,
  parameter C_S00_AXI_DATA_WIDTH  = 32
) (
  input wire clk,
  input wire rstn,

  input [7:0]  octet_in,
  input        octet_in_strobe,
  input [(NUM_OCTET_TOTAL_BITWIDTH-1) : 0] octet_count,
  input [(NUM_OCTET_TOTAL_BITWIDTH-1) : 0] num_octet_total,

  output reg [(C_S00_AXI_DATA_WIDTH-1):0] word_out,
  output reg word_out_strobe
);

reg [31:0] octet_buf;

// octet to word
always @(posedge clk) begin
  if (rstn == 1'b0) begin
    octet_buf <= 0;
    word_out  <= 0;
    word_out_strobe <= 0;
  end else if (octet_in_strobe) begin
    octet_buf[31 : 24] <= octet_in;
    octet_buf[23 : 0]  <= octet_buf[31 : 8];
    word_out_strobe  <= (octet_count[1 : 0] == 3? 1 : 0);
    word_out <= octet_count[1 : 0] == 3? {octet_in, octet_buf[31 : 8]} : word_out;
  end else if (octet_count == num_octet_total) begin
    word_out_strobe <= (octet_count[1 : 0] == 0? 0 : 1);
    case (octet_count[1 : 0])
      2'b01: begin word_out <= {24'b0, octet_buf[31:24]}; end
      2'b10: begin word_out <= {16'b0, octet_buf[31:16]}; end
      2'b11: begin word_out <= { 8'b0, octet_buf[31: 8]}; end
      default: word_out <= word_out;
    endcase
  end else begin
    word_out_strobe <= 0;
  end
end
endmodule

module event_counter_pulse # (
  parameter integer COUNTER_WIDTH = 32
) (
  input wire clk,
  input wire rst,
  input wire pulse_signal,
  output reg [COUNTER_WIDTH-1:0] count
);

always @ (posedge clk) begin
  if (rst) begin
    count <= 0;
  end else begin
    if (pulse_signal) begin
      count <= count + 1;
    end
  end
end
endmodule

module event_counter_level # (
  parameter integer COUNTER_WIDTH = 32
) (
  input wire clk,
  input wire rst,
  input wire level_signal,
  output reg [COUNTER_WIDTH-1:0] count
);

reg level_signal_delay;

always @ (posedge clk) begin
  if (rst) begin
    level_signal_delay <= 0;
    count <= 0;
  end else begin
    level_signal_delay <= level_signal;
    if (level_signal && (level_signal_delay == 0)) begin
      count <= count + 1;
    end
  end
end
endmodule

// ==========================================================
// based on Xilinx module template
// Xianjun jiao. putaoshu@msn.com

`timescale 1 ns / 1 ps

module ll_s_axi #
(
  // Users to add parameters here

  // User parameters ends
  // Do not modify the parameters beyond this line

  // Width of S_AXI data bus
  parameter integer C_S_AXI_DATA_WIDTH  = 32,
  // Width of S_AXI address bus
  parameter integer C_S_AXI_ADDR_WIDTH  = 8
)
(
  // Users to add ports here
  `KEEP_FOR_DBG output wire slv_reg_rden,
  `KEEP_FOR_DBG output wire [5:0] axi_araddr_core,

  `KEEP_FOR_DBG output reg  slv_reg_wren_signal,
  `KEEP_FOR_DBG output wire [5:0] axi_awaddr_core,

  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG0,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG1,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG2,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG3,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG4,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG5,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG6,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG7,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG8,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG9,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG10,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG11,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG12,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG13,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG14,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG15,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG16,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG17,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG18,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG19,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG20,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG21,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG22,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG23,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG24,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG25,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG26,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG27,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG28,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG29,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG30,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG31,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG32,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG33,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG34,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG35,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG36,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG37,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG38,
  output wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG39,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG40,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG41,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG42,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG43,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG44,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG45,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG46,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG47,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG48,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG49,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG50,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG51,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG52,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG53,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG54,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG55,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG56,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG57,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG58,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG59,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG60,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG61,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG62,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] SLV_REG63,
  // User ports ends
  // Do not modify the ports beyond this line

  // Global Clock Signal
  input wire  S_AXI_ACLK,
  // Global Reset Signal. This Signal is Active LOW
  input wire  S_AXI_ARESETN,
  // Write address (issued by master, acceped by Slave)
  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
  // Write channel Protection type. This signal indicates the
  // privilege and security level of the transaction, and whether
  // the transaction is a data access or an instruction access.
  input wire [2 : 0] S_AXI_AWPROT,
  // Write address valid. This signal indicates that the master signaling
  // valid write address and control information.
  input wire  S_AXI_AWVALID,
  // Write address ready. This signal indicates that the slave is ready
  // to accept an address and associated control signals.
  output wire  S_AXI_AWREADY,
  // Write data (issued by master, acceped by Slave) 
  input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
  // Write strobes. This signal indicates which byte lanes hold
  // valid data. There is one write strobe bit for each eight
  // bits of the write data bus.    
  input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
  // Write valid. This signal indicates that valid write
  // data and strobes are available.
  input wire  S_AXI_WVALID,
  // Write ready. This signal indicates that the slave
  // can accept the write data.
  output wire  S_AXI_WREADY,
  // Write response. This signal indicates the status
  // of the write transaction.
  output wire [1 : 0] S_AXI_BRESP,
  // Write response valid. This signal indicates that the channel
  // is signaling a valid write response.
  output wire  S_AXI_BVALID,
  // Response ready. This signal indicates that the master
  // can accept a write response.
  input wire  S_AXI_BREADY,
  // Read address (issued by master, acceped by Slave)
  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
  // Protection type. This signal indicates the privilege
  // and security level of the transaction, and whether the
  // transaction is a data access or an instruction access.
  input wire [2 : 0] S_AXI_ARPROT,
  // Read address valid. This signal indicates that the channel
  // is signaling valid read address and control information.
  input wire  S_AXI_ARVALID,
  // Read address ready. This signal indicates that the slave is
  // ready to accept an address and associated control signals.
  output wire  S_AXI_ARREADY,
  // Read data (issued by slave)
  output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
  // Read response. This signal indicates the status of the
  // read transfer.
  output wire [1 : 0] S_AXI_RRESP,
  // Read valid. This signal indicates that the channel is
  // signaling the required read data.
  output wire  S_AXI_RVALID,
  // Read ready. This signal indicates that the master can
  // accept the read data and response information.
  input wire  S_AXI_RREADY
);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0]   axi_awaddr;
reg         axi_awready;
reg         axi_wready;
reg [1 : 0] axi_bresp;
reg         axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
reg         axi_arready;
reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
reg [1 : 0] axi_rresp;
reg         axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 5;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 64
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg0;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg1;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg2;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg3;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg4;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg5;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg6;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg7;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg8;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg9;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg10;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg11;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg12;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg13;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg14;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg15;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg16;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg17;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg18;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg19;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg20;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg21;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg22;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg23;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg24;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg25;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg26;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg27;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg28;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg29;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg30;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg31;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg32;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg33;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg34;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg35;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg36;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg37;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg38;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg39;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg40;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg41;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg42;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg43;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg44;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg45;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg46;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg47;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg48;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg49;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg50;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg51;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg52;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg53;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg54;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg55;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg56;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg57;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg58;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg59;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg60;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg61;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg62;
reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg63;
// wire    slv_reg_rden;
wire    slv_reg_wren;
reg     [C_S_AXI_DATA_WIDTH-1:0]   reg_data_out;
integer byte_index;
reg     aw_en;

// I/O Connections assignments

assign S_AXI_AWREADY  = axi_awready;
assign S_AXI_WREADY  = axi_wready;
assign S_AXI_BRESP  = axi_bresp;
assign S_AXI_BVALID  = axi_bvalid;
assign S_AXI_ARREADY  = axi_arready;
assign S_AXI_RDATA  = axi_rdata;
assign S_AXI_RRESP  = axi_rresp;
assign S_AXI_RVALID  = axi_rvalid;

assign SLV_REG0 = slv_reg0;
assign SLV_REG1 = slv_reg1;
assign SLV_REG2 = slv_reg2;
assign SLV_REG3 = slv_reg3;
assign SLV_REG4 = slv_reg4;
assign SLV_REG5 = slv_reg5;
assign SLV_REG6 = slv_reg6;
assign SLV_REG7 = slv_reg7;
assign SLV_REG8 = slv_reg8;
assign SLV_REG9 = slv_reg9;
assign SLV_REG10 = slv_reg10;
assign SLV_REG11 = slv_reg11;
assign SLV_REG12 = slv_reg12;
assign SLV_REG13 = slv_reg13;
assign SLV_REG14 = slv_reg14;
assign SLV_REG15 = slv_reg15;
assign SLV_REG16 = slv_reg16;
assign SLV_REG17 = slv_reg17;
assign SLV_REG18 = slv_reg18;
assign SLV_REG19 = slv_reg19;
assign SLV_REG20 = slv_reg20;
assign SLV_REG21 = slv_reg21;
assign SLV_REG22 = slv_reg22;
assign SLV_REG23 = slv_reg23;
assign SLV_REG24 = slv_reg24;
assign SLV_REG25 = slv_reg25;
assign SLV_REG26 = slv_reg26;
assign SLV_REG27 = slv_reg27;
assign SLV_REG28 = slv_reg28;
assign SLV_REG29 = slv_reg29;
assign SLV_REG30 = slv_reg30;
assign SLV_REG31 = slv_reg31;
assign SLV_REG32 = slv_reg32;
assign SLV_REG33 = slv_reg33;
assign SLV_REG34 = slv_reg34;
assign SLV_REG35 = slv_reg35;
assign SLV_REG36 = slv_reg36;
assign SLV_REG37 = slv_reg37;
assign SLV_REG38 = slv_reg38;
assign SLV_REG39 = slv_reg39;

// Implement axi_awready generation
// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // slave is ready to accept write address when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
          begin
            aw_en <= 1'b1;
            axi_awready <= 1'b0;
          end
      else           
        begin
          axi_awready <= 1'b0;
        end
    end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awaddr <= 0;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // Write Address latching 
          axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end       

// Implement axi_wready generation
// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_wready <= 1'b0;
    end 
  else
    begin    
      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
          // slave is ready to accept write data when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_wready <= 1'b1;
        end
      else
        begin
          axi_wready <= 1'b0;
        end
    end 
end       

// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.
assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
assign axi_awaddr_core = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg_wren_signal <= 0;
      slv_reg0 <= 32'h0;
      slv_reg1 <= 32'h0;
      slv_reg2 <= 32'h0;
      slv_reg3 <= 32'h0;
      slv_reg4 <= 32'h0;
      slv_reg5 <= 32'h0;
      slv_reg6 <= 32'h0;
      slv_reg7 <= 32'h0;
      slv_reg8 <= 32'h0;
      slv_reg9 <= 32'h0;
      slv_reg10 <= 32'h0;
      slv_reg11 <= 32'h0;
      slv_reg12 <= 32'h0;
      slv_reg13 <= 32'h0;
      slv_reg14 <= 32'h0;
      slv_reg15 <= 32'h0;
      slv_reg16 <= 32'h0;
      slv_reg17 <= 32'h0;
      slv_reg18 <= 32'h0;
      slv_reg19 <= 32'h0;
      slv_reg20 <= 32'h0;
      slv_reg21 <= 32'h0;
      slv_reg22 <= 32'h0;
      slv_reg23 <= 32'h0;
      slv_reg24 <= 32'h0;
      slv_reg25 <= 32'h0;
      slv_reg26 <= 32'h0;
      slv_reg27 <= 32'h0;
      slv_reg28 <= 32'h0;
      slv_reg29 <= 32'h0;
      slv_reg30 <= 32'h0;
      slv_reg31 <= 32'h0;
      slv_reg32 <= 32'h0;
      slv_reg33 <= 32'h0;
      slv_reg34 <= 32'h0;
      slv_reg35 <= 32'h0;
      slv_reg36 <= 32'h0;
      slv_reg37 <= 32'h0;
      slv_reg38 <= 32'h0;
      slv_reg39 <= 32'h0;
    end 
  else begin
    slv_reg_wren_signal <= slv_reg_wren;
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          6'h00:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 0
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h01:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 1
                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h02:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 2
                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h03:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 3
                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h04:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 4
                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h05:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 5
                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h06:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 6
                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h07:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 7
                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h08:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 8
                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h09:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 9
                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0A:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 10
                slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0B:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 11
                slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0C:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 12
                slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0D:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 13
                slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h0E:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 14
                slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0F:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 15
                slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h10:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 16
                slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h11:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 17
                slv_reg17[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h12:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 18
                slv_reg18[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h13:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 19
                slv_reg19[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h14:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 10
                slv_reg20[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h15:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 11
                slv_reg21[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h16:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 12
                slv_reg22[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h17:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 13
                slv_reg23[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h18:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 14
                slv_reg24[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h19:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 15
                slv_reg25[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h1A:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 16
                slv_reg26[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h1B:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 17
                slv_reg27[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1C:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 18
                slv_reg28[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1D:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 19
                slv_reg29[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1E:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 19
                slv_reg30[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1F:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 19
                slv_reg31[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end
          6'h20:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg32[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h21:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg33[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h22:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg34[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h23:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg35[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h24:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg36[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h25:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg37[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h26:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg38[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          6'h27:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg39[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
          default : begin
                      slv_reg0 <= slv_reg0;
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                      slv_reg4 <= slv_reg4;
                      slv_reg5 <= slv_reg5;
                      slv_reg6 <= slv_reg6;
                      slv_reg7 <= slv_reg7;
                      slv_reg8 <= slv_reg8;
                      slv_reg9 <= slv_reg9;
                      slv_reg10 <= slv_reg10;
                      slv_reg11 <= slv_reg11;
                      slv_reg12 <= slv_reg12;
                      slv_reg13 <= slv_reg13;
                      slv_reg14 <= slv_reg14;
                      slv_reg15 <= slv_reg15;
                      slv_reg16 <= slv_reg16;
                      slv_reg17 <= slv_reg17;
                      slv_reg18 <= slv_reg18;
                      slv_reg19 <= slv_reg19;
                      slv_reg20 <= slv_reg20;
                      slv_reg21 <= slv_reg21;
                      slv_reg22 <= slv_reg22;
                      slv_reg23 <= slv_reg23;
                      slv_reg24 <= slv_reg24;
                      slv_reg25 <= slv_reg25;
                      slv_reg26 <= slv_reg26;
                      slv_reg27 <= slv_reg27;
                      slv_reg28 <= slv_reg28;
                      slv_reg29 <= slv_reg29;
                      slv_reg30 <= slv_reg30;
                      slv_reg31 <= slv_reg31;
                      slv_reg32 <= slv_reg32;
                      slv_reg33 <= slv_reg33;
                      slv_reg34 <= slv_reg34;
                      slv_reg35 <= slv_reg35;
                      slv_reg36 <= slv_reg36;
                      slv_reg37 <= slv_reg37;
                      slv_reg38 <= slv_reg38;
                      slv_reg39 <= slv_reg39;
                    end
        endcase
      end
  end
end    

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_bvalid  <= 0;
      axi_bresp   <= 2'b0;
    end 
  else
    begin    
      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
          // indicates a valid write response is available
          axi_bvalid <= 1'b1;
          axi_bresp  <= 2'b0; // 'OKAY' response 
        end                   // work error responses in future
      else
        begin
          if (S_AXI_BREADY && axi_bvalid) 
            //check if bready is asserted while bvalid is high) 
            //(there is a possibility that bready is always asserted high)   
            begin
              axi_bvalid <= 1'b0; 
            end  
        end
    end
end   

// Implement axi_arready generation
// axi_arready is asserted for one S_AXI_ACLK clock cycle when
// S_AXI_ARVALID is asserted. axi_awready is 
// de-asserted when reset (active low) is asserted. 
// The read address is also latched when S_AXI_ARVALID is 
// asserted. axi_araddr is reset to zero on reset assertion.
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end 
  else
    begin    
      if (~axi_arready && S_AXI_ARVALID)
        begin
          // indicates that the slave has acceped the valid read address
          axi_arready <= 1'b1;
          // Read address latching
          axi_araddr  <= S_AXI_ARADDR;
        end
      else
        begin
          axi_arready <= 1'b0;
        end
    end 
end       

// Implement axi_arvalid generation
// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
// data are available on the axi_rdata bus at this instance. The 
// assertion of axi_rvalid marks the validity of read data on the 
// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
// is deasserted on reset (active low). axi_rresp and axi_rdata are 
// cleared to zero on reset (active low).  
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
    end 
  else
    begin    
      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
          // Valid read data is available at the read data bus
          axi_rvalid <= 1'b1;
          axi_rresp  <= 2'b0; // 'OKAY' response
        end   
      else if (axi_rvalid && S_AXI_RREADY)
        begin
          // Read data is accepted by the master
          axi_rvalid <= 1'b0;
        end                
    end
end    

// Implement memory mapped register select and read logic generation
// Slave register read enable is asserted when valid address is available
// and the slave is ready to accept the read address.
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
assign axi_araddr_core = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
always @(*)
begin
      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        6'h00   : reg_data_out <= slv_reg0;
        6'h01   : reg_data_out <= slv_reg1;
        6'h02   : reg_data_out <= slv_reg2;
        6'h03   : reg_data_out <= slv_reg3;
        6'h04   : reg_data_out <= slv_reg4;
        6'h05   : reg_data_out <= slv_reg5;
        6'h06   : reg_data_out <= slv_reg6;
        6'h07   : reg_data_out <= slv_reg7;
        6'h08   : reg_data_out <= slv_reg8;
        6'h09   : reg_data_out <= slv_reg9;
        6'h0A   : reg_data_out <= slv_reg10;
        6'h0B   : reg_data_out <= slv_reg11;
        6'h0C   : reg_data_out <= slv_reg12;
        6'h0D   : reg_data_out <= slv_reg13;
        6'h0E   : reg_data_out <= slv_reg14;
        6'h0F   : reg_data_out <= slv_reg15;
        6'h10   : reg_data_out <= slv_reg16;
        6'h11   : reg_data_out <= slv_reg17;
        6'h12   : reg_data_out <= slv_reg18;
        6'h13   : reg_data_out <= slv_reg19;
        6'h14   : reg_data_out <= slv_reg20;
        6'h15   : reg_data_out <= slv_reg21;
        6'h16   : reg_data_out <= slv_reg22;
        6'h17   : reg_data_out <= slv_reg23;
        6'h18   : reg_data_out <= slv_reg24;
        6'h19   : reg_data_out <= slv_reg25;
        6'h1A   : reg_data_out <= slv_reg26;
        6'h1B   : reg_data_out <= slv_reg27;
        6'h1C   : reg_data_out <= slv_reg28;
        6'h1D   : reg_data_out <= slv_reg29;
        6'h1E   : reg_data_out <= slv_reg30;
        6'h1F   : reg_data_out <= slv_reg31;
        6'h20   : reg_data_out <= slv_reg32;
        6'h21   : reg_data_out <= slv_reg33;
        6'h22   : reg_data_out <= slv_reg34;
        6'h23   : reg_data_out <= slv_reg35;
        6'h24   : reg_data_out <= slv_reg36;
        6'h25   : reg_data_out <= slv_reg37;
        6'h26   : reg_data_out <= slv_reg38;
        6'h27   : reg_data_out <= slv_reg39;
        6'h28   : reg_data_out <= SLV_REG40;
        6'h29   : reg_data_out <= SLV_REG41;
        6'h2A   : reg_data_out <= SLV_REG42;
        6'h2B   : reg_data_out <= SLV_REG43;
        6'h2C   : reg_data_out <= SLV_REG44;
        6'h2D   : reg_data_out <= SLV_REG45;
        6'h2E   : reg_data_out <= SLV_REG46;
        6'h2F   : reg_data_out <= SLV_REG47;
        6'h30   : reg_data_out <= SLV_REG48;
        6'h31   : reg_data_out <= SLV_REG49;
        6'h32   : reg_data_out <= SLV_REG50;
        6'h33   : reg_data_out <= SLV_REG51;
        6'h34   : reg_data_out <= SLV_REG52;
        6'h35   : reg_data_out <= SLV_REG53;
        6'h36   : reg_data_out <= SLV_REG54;
        6'h37   : reg_data_out <= SLV_REG55;
        6'h38   : reg_data_out <= SLV_REG56;
        6'h39   : reg_data_out <= SLV_REG57;
        6'h3A   : reg_data_out <= SLV_REG58;
        6'h3B   : reg_data_out <= SLV_REG59;
        6'h3C   : reg_data_out <= SLV_REG60;
        6'h3D   : reg_data_out <= SLV_REG61;
        6'h3E   : reg_data_out <= SLV_REG62;
        6'h3F   : reg_data_out <= SLV_REG63;
        default : reg_data_out <= 0;
      endcase
end

// Output register or memory read data
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rdata  <= 0;
    end 
  else
    begin    
      // When there is a valid read address (S_AXI_ARVALID) with 
      // acceptance of read address by the slave (axi_arready), 
      // output the read dada 
      if (slv_reg_rden)
        begin
          axi_rdata <= reg_data_out;     // register read data
        end   
    end
end    

// Add user logic here

// User logic ends

endmodule

`timescale 1ns / 1ps

// NOTE: uart_frame_rx / uart_frame_tx / tx_clk_gen / rx_clk_gen /
// sdpram_one_clk / sdpram_two_clk are maintained in standalone files
// under verilog/ and are intentionally not duplicated here.

module clk_cross_bus #
(
  parameter DATA_WIDTH = 8
) (
  input wire write_clk,
  `KEEP_FOR_DBG input wire rst,

  `KEEP_FOR_DBG input wire [DATA_WIDTH-1:0] write_data,

  input  wire read_clk,
  `KEEP_FOR_DBG output wire [DATA_WIDTH-1:0] read_data
);

`define CROSS_CLK_BY_DPRAM

`ifdef CROSS_CLK_BY_DPRAM

sdpram_two_clk #
(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_WIDTH(1)
) sdpram_two_clk_for_clk_cross_bus_i (
  .clk(write_clk),
  .rst(rst),

  .write_address(1'd0),
  .write_data(write_data),
  .write_enable(1'd1),

  .clkb(read_clk),
  .read_address(1'd0),
  .read_data(read_data)
);

`else

`KEEP_FOR_DBG reg [DATA_WIDTH-1:0] write_data_delay;
`KEEP_FOR_DBG reg wr_en;

`KEEP_FOR_DBG wire [3:0] rd_data_count;
`KEEP_FOR_DBG wire [3:0] wr_data_count;

`KEEP_FOR_DBG wire empty;
`KEEP_FOR_DBG wire full;
`KEEP_FOR_DBG wire data_valid;
`KEEP_FOR_DBG wire underflow;
`KEEP_FOR_DBG wire wr_ack;
`KEEP_FOR_DBG wire wr_rst_busy;
`KEEP_FOR_DBG wire rd_rst_busy;
`KEEP_FOR_DBG wire overflow;

always @ (posedge write_clk) begin
  if (rst) begin
    write_data_delay <= {DATA_WIDTH{1'b0}};
    wr_en <= 1'b0;
  end else begin
    write_data_delay <= write_data;
    if (write_data != write_data_delay) begin
      wr_en <= 1'b1;
    end else begin
      wr_en <= 1'b0;
    end
  end
end

xpm_fifo_async #(
  .CASCADE_HEIGHT(0),            // DECIMAL
  .CDC_SYNC_STAGES(2),           // DECIMAL
  .DOUT_RESET_VALUE("0"),        // String
  .ECC_MODE("no_ecc"),           // String
//  .EN_SIM_ASSERT_ERR("warning"), // String
  .FIFO_MEMORY_TYPE("auto"),     // String
  .FIFO_READ_LATENCY(0),         // DECIMAL
  .FIFO_WRITE_DEPTH(16),         // DECIMAL
  .FULL_RESET_VALUE(0),          // DECIMAL
  .PROG_EMPTY_THRESH(10),        // DECIMAL
  .PROG_FULL_THRESH(10),         // DECIMAL
  .RD_DATA_COUNT_WIDTH(4),       // DECIMAL
  .READ_DATA_WIDTH(DATA_WIDTH),  // DECIMAL
  .READ_MODE("fwft"),            // String
  .RELATED_CLOCKS(0),            // DECIMAL
  .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_ADV_FEATURES("1717"),     // String
  .WAKEUP_TIME(0),               // DECIMAL
  .WRITE_DATA_WIDTH(DATA_WIDTH), // DECIMAL
  .WR_DATA_COUNT_WIDTH(4)        // DECIMAL
)
xpm_fifo_async_clk_cross_inst (
  .almost_empty(almost_empty),   // 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed
                                 // before the FIFO goes to empty.

  .almost_full(almost_full),     // 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed
                                 // before the FIFO is full.

  .data_valid(data_valid),       // 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the
                                 // output bus (dout).

  .dbiterr(dbiterr),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the
                                 // FIFO core is corrupted.

  .dout(read_data),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
  .empty(empty),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the FIFO is empty. Read requests are
                                 // ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.

  .full(full),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are
                                 // ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive to the contents of
                                 // the FIFO.

  .overflow(overflow),           // 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was
                                 // rejected, because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.

  .prog_empty(prog_empty),       // 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than
                                 // or equal to the programmable empty threshold value. It is de-asserted when the number of words in the FIFO
                                 // exceeds the programmable empty threshold value.

  .prog_full(prog_full),         // 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than
                                 // or equal to the programmable full threshold value. It is de-asserted when the number of words in the FIFO is
                                 // less than the programmable full threshold value.

  .rd_data_count(rd_data_count), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
  .rd_rst_busy(rd_rst_busy),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
  .sbiterr(sbiterr),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
  .underflow(underflow),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected
                                 // because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.

  .wr_ack(wr_ack),               // 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock
                                 // cycle is succeeded.

  .wr_data_count(wr_data_count), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the
                                 // FIFO.

  .wr_rst_busy(wr_rst_busy),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset
                                 // state.

  .din(write_data_delay),        // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
  .injectdbiterr(injectdbiterr), // 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs
                                 // or UltraRAM macros.

  .injectsbiterr(injectsbiterr), // 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs
                                 // or UltraRAM macros.

  .rd_clk(read_clk),             // 1-bit input: Read clock: Used for read operation. rd_clk must be a free running clock.
  .rd_en(1'b1),                  // 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read
                                 // from the FIFO. Must be held active-low when rd_rst_busy is active high.

  .rst(rst),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be unstable at the time of applying
                                 // reset, but reset must be released only after the clock(s) is/are stable.

  .sleep(sleep),                 // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
  .wr_clk(write_clk),            // 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
  .wr_en(wr_en)                  // 1-bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written
                                 // to the FIFO. Must be held active-low when rst or wr_rst_busy is active high.
);

`endif

endmodule

// `pragma protect end
