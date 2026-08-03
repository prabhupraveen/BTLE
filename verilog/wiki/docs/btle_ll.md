# btle_ll

## Description
TODO: Add description

## Parameters
- C_S00_AXI_DATA_WIDTH  = 32
- C_S00_AXI_ADDR_WIDTH  = 8
- CLK_FREQUENCE = 100_000_000  (= 100000000)
- BAUD_RATE     = 115200
- PARITY = "NONE"  (unresolved)
- FRAME_WD      = 8
- RF_IQ_BIT_WIDTH = 64
- RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4)  (= 16)
- GAUSS_FILTER_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32
- NUM_BIT_PAYLOAD_LENGTH = 8

## Inputs
- bb_clk
- bb_rst
- ref_1pps
- uart_rx
- tx_iq_valid_last
- rx_hit_flag
- rx_decode_run
- rx_decode_end
- rx_crc_ok
- rx_payload_length [(NUM_BIT_PAYLOAD_LENGTH-1):0]
- rx_pdu_octet_mem_data [7:0]
- bram_addr_b_half_flag
- bram_addr_b [C_S00_AXI_DATA_WIDTH-1 : 0]
- rx_i_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_q_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_iq_valid
- i_abs_add_q_abs [RF_I_OR_Q_BIT_WIDTH : 0]
- agc_lock_change
- agc_lock_state
- rf_gain [6:0]
- simulation_en
- simulation_rx_ram_read_en
- axi_aclk
- axi_aresetn
- axi_awaddr [C_S00_AXI_ADDR_WIDTH-1 : 0]
- axi_awprot [2 : 0]
- axi_awvalid
- axi_wdata [C_S00_AXI_DATA_WIDTH-1 : 0]
- axi_wstrb [(C_S00_AXI_DATA_WIDTH/8)-1 : 0]
- axi_wvalid
- axi_bready
- axi_araddr [C_S00_AXI_ADDR_WIDTH-1 : 0]
- axi_arprot [2 : 0]
- axi_arvalid
- axi_rready

## Outputs
- uart_tx
- tx_gauss_filter_tap_index [3:0]
- tx_gauss_filter_tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- tx_cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- tx_cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- tx_sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- tx_sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- tx_preamble [7:0]
- tx_access_address [31:0]
- tx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- tx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- tx_pdu_octet_mem_data [7:0]
- tx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]
- tx_start
- phy_2m_mode
- phy_test_mode [2:0]
- rx_unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- rx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- rx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- rx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]
- ll_gpio [15:0]
- ll_itrpt0
- ll_itrpt1
- ll_itrpt2
- ll_itrpt3
- ll_itrpt4
- ll_itrpt5
- ll_itrpt6
- ll_itrpt7
- axi_awready
- axi_wready
- axi_bresp [1 : 0]
- axi_bvalid
- axi_arready
- axi_rdata [C_S00_AXI_DATA_WIDTH-1 : 0]
- axi_rresp [1 : 0]
- axi_rvalid

## Inouts
- None

## Calls
- [clk_cross_bus](clk_cross_bus.md)
- [sdpram_one_clk](sdpram_one_clk.md)
- [uart_frame_rx](uart_frame_rx.md)
- [uart_frame_tx](uart_frame_tx.md)

## Called By
- [btle_controller](btle_controller.md)
