# serial_in_ram_out

## Description
This module acts as an asynchronous buffer, converting a streamed sequence of valid data into random-access memory storage.
- Address Generation: It maintains an internal counter that automatically increments the write address every time a new valid data byte/bit arrives.
- Cross-Domain Storage: It instantiates the dual-clock RAM (`sdpram_two_clk`) to store the incoming stream using the write clock, while allowing external components to fetch any stored data asynchronously using a separate read clock.

## Inputs
- clk
- rst
- data_in
- data_in_valid
- clkb
- addr

## Outputs
- data

## Calls
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_rx](btle_rx.md)
