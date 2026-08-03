# btle_tx

## Description
TODO: Add description

## Parameters
- NUM_BIT_PAYLOAD_LENGTH = 8
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- SAMPLE_PER_SYMBOL = 8
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode [2:0]
- gauss_filter_tap_index [3:0]
- gauss_filter_tap_value [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- cos_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- cos_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- sin_table_write_address [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]
- sin_table_write_data [(IQ_BIT_WIDTH-1) : 0]
- preamble [7:0]
- access_address [31:0]
- crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- crc_state_init_bit_load
- channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- channel_number_load
- pdu_octet_mem_data [7:0]
- pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]
- tx_start

## Outputs
- i [(IQ_BIT_WIDTH-1) : 0]
- q [(IQ_BIT_WIDTH-1) : 0]
- iq_valid
- iq_valid_last
- phy_bit
- phy_bit_valid
- phy_bit_valid_last
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last
- bit_upsample_gauss_filter [(GAUSS_FILTER_BIT_WIDTH-1) : 0]
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Inouts
- None

## Calls
- [crc24](crc24.md)
- [gfsk_modulation](gfsk_modulation.md)
- [scramble](scramble.md)
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_phy](btle_phy.md)
