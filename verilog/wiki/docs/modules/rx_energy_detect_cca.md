# rx_energy_detect_cca

## Description
This module implements a Clear Channel Assessment (CCA) function to determine if the radio frequency medium is currently occupied.  
- **Energy Estimation**: It calculates a simplified signal magnitude by summing the absolute values of the I and Q samples ($|I| + |Q|$), avoiding the need for complex multipliers.  
- **Averaging Window**: It accumulates these magnitude values over a programmable window and calculates an average energy level.  
- **Busy Channel Detection**: It compares the averaged energy against a set threshold and asserts a `cca_busy` flag if the energy level is too high. 

## Inputs
- clk
- rst
- i
- q
- iq_valid
- ed_threshold

## Outputs
- cca_busy
- ed_level
- ed_valid

## Calls

## Called By
- [btle_rx](btle_rx.md)
