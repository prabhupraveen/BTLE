# sdpram_one_clk

## Description
This is a standard Simple Dual-Port Block RAM (BRAM) module driven by a single clock.
- **Write Operation**: It writes incoming data to a specified memory address on the rising edge of the clock, provided the write enable signal is active.
- **Read Operation**: It continuously reads data from a provided read address and outputs it on the rising edge of the same clock.

## Inputs
- clk
- rst
- write_address
- write_data
- write_enable
- read_address

## Outputs
- read_data

## Calls

## Called By
- [btle_ll](btle_ll.md)
- [vco](vco.md)
