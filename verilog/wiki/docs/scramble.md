# scramble

## Description
TODO: Add description

## Parameters
- NUM_BIT_PAYLOAD_LENGTH = 8
- CHANNEL_NUMBER_BIT_WIDTH = 6

## Inputs
- clk
- rst
- channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- channel_number_load
- data_in
- data_in_valid
- data_in_valid_last

## Outputs
- data_out
- data_out_valid
- data_out_valid_last

## Inouts
- None

## Calls
- [scramble_core](scramble_core.md)

## Called By
- [btle_tx](btle_tx.md)
