# scramble

## Description
This is the high-level controller that manages when the scrambling process should actually be applied to the data stream.
- **Preamble Management**: It tracks the bit count to ensure the first 40 bits of a packet (the preamble and access address) are passed through untouched, as the Bluetooth spec requires these to remain unscrambled.
- **Flow Synchronization**: It uses internal delays and counters to align the "scrambled" data from the core with the original packet timing. It manages the transition from passing raw header data to passing scrambled payload data.
- **Signal Coordination**: It acts as the primary interface for external hardware, providing synchronized valid and "last bit" signals to indicate the status of the processed bitstream.

## Inputs
- clk
- rst
- channel_number
- channel_number_load
- data_in
- data_in_valid
- data_in_valid_last

## Outputs
- data_out
- data_out_valid
- data_out_valid_last

## Calls
- [scramble_core](scramble_core.md)

## Called By
- [btle_tx](btle_tx.md)
