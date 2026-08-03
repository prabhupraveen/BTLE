# btle_phy

## Description
TODO: Add description

## Parameters
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- SAMPLE_PER_SYMBOL = 8
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32
- NUM_BIT_PAYLOAD_LENGTH = 8
- RF_I_OR_Q_BIT_WIDTH = 16

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode [2:0]
- tx_gauss_filter_tap_index [3:0]
- tx_gauss_filter_tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- tx_cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- tx_cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- tx_sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- tx_sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- tx_preamble [7:0]
- tx_access_address [31:0]
- tx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- tx_crc_state_init_bit_load
- tx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- tx_channel_number_load
- tx_pdu_octet_mem_data [7:0]
- tx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]
- tx_start
- rx_unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- rx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- rx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- rx_i_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_q_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_iq_valid
- rx_magnitude [RF_I_OR_Q_BIT_WIDTH : 0]
- rx_pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]

## Outputs
- tx_i_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_q_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_iq_valid
- tx_iq_valid_last
- tx_phy_bit
- tx_phy_bit_valid
- tx_phy_bit_valid_last
- tx_bit_upsample
- tx_bit_upsample_valid
- tx_bit_upsample_valid_last
- tx_bit_upsample_gauss_filter [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- tx_bit_upsample_gauss_filter_valid
- tx_bit_upsample_gauss_filter_valid_last
- rx_hit_flag
- rx_decode_run
- rx_decode_end
- rx_crc_ok
- rx_best_phase [2:0]
- rx_payload_length [(NUM_BIT_PAYLOAD_LENGTH-1):0]
- rx_pdu_octet_mem_data [7:0]

## Inouts
- None

## Calls
- [btle_rx](btle_rx.md)
- [btle_tx](btle_tx.md)

## Called By
- [btle_controller](btle_controller.md)
