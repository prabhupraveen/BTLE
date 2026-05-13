# scramble_core

## Description
This is the bit-level processing engine. It uses a 7-bit Linear Feedback Shift Register (LFSR) to generate a pseudo-random sequence.
- **Initialization**: It loads a 6-bit channel number into the LFSR when triggered. It also sets a constant "1" in the first position of the register to ensure the scrambler starts in a valid state.
- **Data Scrambling**: When data_in_valid is high, it performs an XOR operation between the incoming data bit and the current state of the LFSR. This "whitens" the data by mixing it with the pseudo-random bits.
- **State Maintenance**: It updates the LFSR state on every valid bit using a specific polynomial feedback loop (XORing bits 4 and 6) to prepare for the next bit.

## Inputs
- clk
- rst
- channel_number
- channel_number_load
- data_in
- data_in_valid

## Outputs
- data_out
- data_out_valid

## Calls

## Called By
- [btle_rx_core](btle_rx_core.md)
- [scramble](scramble.md)
