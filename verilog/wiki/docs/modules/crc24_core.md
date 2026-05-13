# crc24_core

## Description
This is the computational engine of the system. It implements a Linear Feedback Shift Register (LFSR).
- **Initialization**: It loads a starting 24-bit state (seed). Notably, it performs a byte-swap on the input initialization bits to match specific endianness requirements.
- **CRC Calculation**: When data_in_valid is high, it updates the LFSR using a specific generator polynomial. It uses XOR gates at specific taps (positions) to mix the incoming data bit into the 24-bit state.
- **State Maintenance**: It holds the current running CRC value in the lfsr register.

## Inputs
- clk
- rst
- crc_state_init_bit
- crc_state_init_bit_load
- data_in
- data_in_valid

## Outputs
- lfsr

## Calls

## Called By
- [btle_rx_core](btle_rx_core.md)
- [crc24](crc24.md)
