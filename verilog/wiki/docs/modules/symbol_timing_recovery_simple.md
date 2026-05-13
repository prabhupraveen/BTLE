# symbol_timing_recovery_simple

## Description
This module identifies and tracks the optimal moment to sample bits in a demodulated signal by choosing the best of multiple oversampled phases.  
- **Metric Tracking**: It maintains an accumulation of signal quality metrics for every available sampling phase over a window of several symbols.  
- **Dynamic Phase Selection**: It periodically evaluates these metrics to select the "best" phase (the one with the highest energy or decision magnitude) to account for slight timing drifts.  
- **Data Decimation**: It converts high-speed oversampled data into a symbol-rate stream by outputting samples only at the chosen optimal timing point. 

## Inputs
- clk
- rst
- decision_in
- decision_valid
- update_period_sym_runtime

## Outputs
- phase_sel
- sym_strobe
- decision_sym

## Calls

## Called By
- [btle_rx_core](btle_rx_core.md)
