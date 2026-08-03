# crc24

## Description
TODO: Add description

## Parameters
- NUM_BIT_PAYLOAD_LENGTH = 8
- CRC_STATE_BIT_WIDTH = 24

## Inputs
- clk
- rst
- crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- crc_state_init_bit_load
- info_bit
- info_bit_valid
- info_bit_valid_last

## Outputs
- info_bit_after_crc24
- info_bit_after_crc24_valid
- info_bit_after_crc24_valid_last

## Inouts
- None

## Calls
- [crc24_core](crc24_core.md)

## Called By
- [btle_tx](btle_tx.md)
