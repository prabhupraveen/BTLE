# scramble_core

## Description
TODO: Add description

## Parameters
- CHANNEL_NUMBER_BIT_WIDTH = 6

## Inputs
- clk
- rst
- channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- channel_number_load
- data_in
- data_in_valid

## Outputs
- data_out
- data_out_valid

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx_core](btle_rx_core.md)
- [scramble](scramble.md)
