# bit_repeat_upsample

## Description
This module performs sample rate conversion by repeating input bits to match the higher clock frequency required for the modulation chain.  
- **Rate Conversion**: It takes 1 Mbps or 2 Mbps input bits and upsamples them to an 8 Mbps rate to feed the Gaussian filter.  
- **Adaptive Oversampling**: It dynamically adjusts the number of repetitions per bit based on whether the system is in 2M mode or 16x oversampling mode.  
- **Flow Control**: It manages internal counters to ensure the "last bit" signal is correctly timed and asserted only after the final repeated sample of a packet has been sent.  

## Inputs
- clk
- rst
- phy_2m_mode
- phy_bit
- bit_valid
- bit_valid_last
- osr_16x_en

## Outputs
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last

## Calls

## Called By
- [gfsk_modulation](gfsk_modulation.md)
