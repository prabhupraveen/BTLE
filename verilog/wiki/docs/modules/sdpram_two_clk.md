# sdpram_two_clk

## Description
This is a Simple Dual-Port Block RAM designed to operate across two different clock domains.
- **Write Operation (Port A)**: It handles incoming data writes synchronously using the primary clock (`clk`) when the write enable is high.
- **Read Operation (Port B)**: It outputs requested memory data synchronously using a secondary, independent clock (`clkb`).

## Inputs
- clk
- rst
- write_address
- write_data
- write_enable
- clkb
- read_address

## Outputs
- read_data

## Calls

## Called By
- [btle_tx](btle_tx.md)
- [clk_cross_bus](clk_cross_bus.md)
- [serial_in_ram_out](serial_in_ram_out.md)
