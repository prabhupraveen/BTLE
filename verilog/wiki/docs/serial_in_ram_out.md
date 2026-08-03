# serial_in_ram_out

## Description
TODO: Add description

## Parameters
- DATA_WIDTH = 8
- ADDRESS_WIDTH = 6

## Inputs
- clk
- rst
- data_in [(DATA_WIDTH-1) : 0]
- data_in_valid
- clkb
- addr [(ADDRESS_WIDTH-1) : 0]

## Outputs
- data [(DATA_WIDTH-1) : 0]

## Inouts
- None

## Calls
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_rx](btle_rx.md)
