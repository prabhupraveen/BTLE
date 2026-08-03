# clk_cross_bus

## Description
TODO: Add description

## Parameters
- DATA_WIDTH = 8

## Inputs
- write_clk
- rst (`KEEP_FOR_DBG)
- write_data [DATA_WIDTH-1:0]
- read_clk

## Outputs
- read_data [DATA_WIDTH-1:0]

## Inouts
- None

## Calls
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_ll](btle_ll.md)
