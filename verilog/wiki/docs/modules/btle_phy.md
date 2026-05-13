# btle_phy

## Description
TODO: Add description

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode
- tx_gauss_filter_tap_index
- tx_gauss_filter_tap_value
- tx_cos_table_write_address
- tx_cos_table_write_data
- tx_sin_table_write_address
- tx_sin_table_write_data
- tx_preamble
- tx_access_address
- tx_crc_state_init_bit
- tx_crc_state_init_bit_load
- tx_channel_number
- tx_channel_number_load
- tx_pdu_octet_mem_data
- tx_pdu_octet_mem_addr
- tx_start
- rx_unique_bit_sequence
- rx_channel_number
- rx_crc_state_init_bit
- rx_i_signal
- rx_q_signal
- rx_iq_valid
- rx_pdu_octet_mem_addr

## Outputs
- tx_i_signal
- tx_q_signal
- tx_iq_valid
- tx_iq_valid_last
- tx_phy_bit
- tx_phy_bit_valid
- tx_phy_bit_valid_last
- tx_bit_upsample
- tx_bit_upsample_valid
- tx_bit_upsample_valid_last
- tx_bit_upsample_gauss_filter
- tx_bit_upsample_gauss_filter_valid
- tx_bit_upsample_gauss_filter_valid_last
- rx_hit_flag
- rx_decode_run
- rx_decode_end
- rx_crc_ok
- rx_best_phase
- rx_payload_length
- rx_pdu_octet_mem_data

## Calls
- [btle_rx](btle_rx.md)
- [btle_tx](btle_tx.md)

## Called By
- [btle_controller](btle_controller.md)
