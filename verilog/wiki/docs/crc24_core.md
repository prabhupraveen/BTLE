# crc24_core

## Description
TODO: Add description

## Parameters
- CRC_STATE_BIT_WIDTH = 24

## Inputs
- clk
- rst
- crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- crc_state_init_bit_load
- data_in
- data_in_valid

## Outputs
- lfsr [(CRC_STATE_BIT_WIDTH-1) : 0]

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx_core](btle_rx_core.md)
- [crc24](crc24.md)
