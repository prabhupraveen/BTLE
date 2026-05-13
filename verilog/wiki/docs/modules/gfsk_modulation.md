# gfsk_modulation

## Description
This is a high-level modulator that converts raw digital bits into complex I/Q (In-phase and Quadrature) signals ready for RF transmission.
- **Signal Processing Chain**: It integrates bit upsampling, Gaussian filtering, and a Voltage Controlled Oscillator (VCO) to transform bits into frequency-modulated waveforms.  
- **Frequency Deviation Scaling**: It adjusts the amplitude of the filtered signal (deviation) based on the selected PHY mode (e.g., 1M vs. 2M) before passing it to the VCO.  
- **Waveform Generation**: It uses Sine and Cosine look-up tables within the VCO to output the digital representation of the modulated carrier wave.

## Inputs
- clk
- rst
- phy_2m_mode
- osr_16x_en
- gauss_filter_tap_index
- gauss_filter_tap_value
- cos_table_write_address
- cos_table_write_data
- sin_table_write_address
- sin_table_write_data
- phy_bit
- bit_valid
- bit_valid_last

## Outputs
- cos_out
- sin_out
- sin_cos_out_valid
- sin_cos_out_valid_last
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last
- bit_upsample_gauss_filter
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Calls
- [bit_repeat_upsample](bit_repeat_upsample.md)
- [gauss_filter](gauss_filter.md)
- [vco](vco.md)

## Called By
- [btle_tx](btle_tx.md)
