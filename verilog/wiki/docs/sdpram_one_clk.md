# sdpram_one_clk

## Description
TODO: Add description

## Parameters
- DATA_WIDTH = 8
- ADDRESS_WIDTH = 11

## Inputs
- clk
- rst
- write_address [ADDRESS_WIDTH-1:0]
- write_data [DATA_WIDTH-1:0]
- write_enable
- read_address [ADDRESS_WIDTH-1:0]

## Outputs
- read_data [DATA_WIDTH-1:0]

## Inouts
- None

## Calls
- None

## Called By
- [btle_ll](btle_ll.md)
- [vco](vco.md)
