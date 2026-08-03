# search_unique_bit_sequence

## Description
This module acts as a strict pattern matcher, looking for an exact bit sequence (like an Access Address) in a continuous data stream.
- **Data Shifting**: It captures valid incoming bits and shifts them through an internal register to keep a running history of the most recently received bits.
- **Exact Matching**: It continuously compares the running history against a target sequence. If they match perfectly (zero bit errors allowed), it triggers a hit flag.

## Inputs
- clk
- rst
- phy_bit
- bit_valid
- unique_bit_sequence

## Outputs
- hit_flag
## Calls

## Called By
- [btle_rx_core](btle_rx_core.md)

## See also
- [aa_correlator_threshold](aa_correlator_threshold.md) - A similar module that allows for a configurable number of bit errors in the match. (Should be used when we need working in high SnR)