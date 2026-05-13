# vco

## Description
This module implements a digital Voltage Controlled Oscillator used to generate frequency-modulated I/Q waveforms.  
- **Frequency to Phase Integration**: It treats the input `voltage_signal` as a frequency control, integrating it over time to determine the current phase of the carrier wave.  
- **Lookup Table Synthesis**: It uses the integrated phase to read corresponding values from pre-calculated sine and cosine tables stored in memory.  
- **Stream Coordination**: It manages synchronization signals to ensure the generated waveform samples are correctly aligned with the original input data bits.  

## Inputs
- clk
- rst
- cos_table_write_address
- cos_table_write_data
- sin_table_write_address
- sin_table_write_data
- voltage_signal
- voltage_signal_valid
- voltage_signal_valid_last

## Outputs
- cos_out
- sin_out
- sin_cos_out_valid
- sin_cos_out_valid_last

## Calls
- [sdpram_one_clk](sdpram_one_clk.md)

## Called By
- [gfsk_modulation](gfsk_modulation.md)
