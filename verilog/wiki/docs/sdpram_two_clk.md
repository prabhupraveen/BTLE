# sdpram_two_clk

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
- clkb
- read_address [ADDRESS_WIDTH-1:0]

## Outputs
- read_data [DATA_WIDTH-1:0]

## Inouts
- None

## Calls
- None

## Called By
- [auxiliary_daemon](auxiliary_daemon.md)
- [btle_tx](btle_tx.md)
- [clk_cross_bus](clk_cross_bus.md)
- [serial_in_ram_out](serial_in_ram_out.md)
