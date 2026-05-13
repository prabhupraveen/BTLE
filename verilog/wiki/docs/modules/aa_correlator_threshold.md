# aa_correlator_threshold

## Description
This module identifies the start of a Bluetooth packet by searching for a specific "Access Address" (AA) bit sequence within the incoming bitstream. Unlike a basic exact-match correlator, this version supports fuzzy logic to improve reliability in noisy environments.
- **Hamming Distance Calculation**: It continuously compares the last 32 bits received against a target address and counts the number of mismatches using an XOR-based popcount.  
- **Programmable Threshold**: It triggers a "hit" flag if the number of matching bits meets or exceeds a user-defined threshold, allowing for a specific number of bit errors.  
- **Telemetry**: It outputs a real-time "score" (the count of matching bits) which can be used for system tuning or monitoring signal quality. 

## Inputs
- clk
- rst
- phy_bit
- bit_valid
- aa_target
- aa_threshold

## Outputs
- hit_flag
- score

## Calls

## Called By
- None

## See Also
- [search_unique_bit_sequence](search_unique_bit_sequence.md) - A similar module that requires an exact match with zero bit errors. (Written by Xianjun Jiao)