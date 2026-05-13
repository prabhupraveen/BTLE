# btle_rx_core

## Description
This is the central receiver controller that manages the digital signal processing chain to extract and validate Bluetooth Low Energy (BTLE) packets.
- **State Machine Management**: It uses a finite state machine to transition from an idle state to length extraction and finally CRC verification once a valid packet header is detected.  
- **Packet Parsing**: It tracks bit and octet counts to slice the incoming bitstream into meaningful fields, such as the payload length and the CRC.  
- **Sub-Module Coordination**: It orchestrates various specialized components including the GFSK demodulator, symbol timing recovery, search for unique bit sequences (access addresses), and the descrambler.

## Inputs
- clk
- phy_2m_mode
- phy_test_mode
- unique_bit_sequence
- channel_number
- crc_state_init_bit
- i
- q
- iq_valid

## Outputs

## Calls
- [crc24_core](crc24_core.md)
- [gfsk_demodulation](gfsk_demodulation.md)
- [scramble_core](scramble_core.md)
- [search_unique_bit_sequence](search_unique_bit_sequence.md)
- [symbol_timing_recovery_simple](symbol_timing_recovery_simple.md)

## Called By
- [btle_rx](btle_rx.md)
