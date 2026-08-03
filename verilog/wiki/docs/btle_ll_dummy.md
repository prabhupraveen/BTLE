# btle_ll_dummy

## Description
TODO: Add description

## Parameters
- CLK_FREQUENCE = 16_000_000  (= 16000000)
- BAUD_RATE		= 115200
- PARITY = "NONE"  (unresolved)
- FRAME_WD		= 8
- GAUSS_FILTER_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- LEN_UNIQUE_BIT_SEQUENCE = 32

## Inputs
- clk
- rst
- uart_rx
- tx_iq_valid_last
- rx_hit_flag
- rx_decode_run
- rx_decode_end
- rx_crc_ok
- rx_payload_length [6:0]
- rx_pdu_octet_mem_data [7:0]

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
- tx_pdu_octet_mem_addr [5:0]
- tx_start
- rx_unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- rx_channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- rx_crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- rx_pdu_octet_mem_addr [5:0]

## Inouts
- None

## Calls
- [uart_frame_rx](uart_frame_rx.md)
- [uart_frame_tx](uart_frame_tx.md)

## Called By
- None
