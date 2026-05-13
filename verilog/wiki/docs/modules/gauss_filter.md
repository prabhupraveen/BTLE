# gauss_filter

## Description
This module implements a Gaussian Pulse-Shaping filter, which is used to smooth transitions between bits to limit the bandwidth of the transmitted signal.
- **FIR Implementation**: It functions as a Finite Impulse Response (FIR) filter using 17 taps, where the coefficients (tap values) are programmable.  
- **Symmetric Filtering**: It stores a history of upsampled bits and applies the Gaussian coefficients to the current and previous bit values to calculate a filtered output.  
- **BTLE Compliance**: The design specifically targets the BT=0.5 specification required by Bluetooth standards for GFSK modulation.

## Inputs
- clk
- rst
- tap_index
- tap_value
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last

## Outputs
- bit_upsample_gauss_filter
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Calls

## Called By
- [gfsk_modulation](gfsk_modulation.md)
