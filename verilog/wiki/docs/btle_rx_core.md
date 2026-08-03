# btle_rx_core

## Description
TODO: Add description

## Parameters
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32
- CHANNEL_NUMBER_BIT_WIDTH = 6
- CRC_STATE_BIT_WIDTH = 24
- NUM_BIT_PAYLOAD_LENGTH = 8

## Inputs
- clk
- rst
- phy_2m_mode
- phy_test_mode [2:0]
- unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- i [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- q [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- iq_valid

## Outputs
- hit_flag
- payload_length_out [(NUM_BIT_PAYLOAD_LENGTH-1) : 0]
- payload_length_valid
- info_bit
- bit_valid
- octet [7:0]
- octet_valid
- decode_end
- crc_ok

## Inouts
- None

## Calls
- [crc24_core](crc24_core.md)
- [gfsk_demodulation](gfsk_demodulation.md)
- [scramble_core](scramble_core.md)
- [search_unique_bit_sequence](search_unique_bit_sequence.md)
- [symbol_timing_recovery_simple](symbol_timing_recovery_simple.md)

## Called By
- [btle_rx](btle_rx.md)
