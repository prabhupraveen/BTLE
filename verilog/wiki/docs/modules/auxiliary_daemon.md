# auxiliary_daemon

## Description
This module acts as a support utility that extracts signal metadata and hardware status to assist the Bluetooth Link Layer.  
- Magnitude Estimation: It computes the absolute values of the incoming I and Q samples and sums them to provide a quick estimate of the signal strength ($|I| + |Q|$).  
- Gain and Lock Tracking: It parses general-purpose input signals (bb_gpio) to extract the current RF gain settings and detect when the Automatic Gain Control (AGC) has changed its lock status.

## Inputs
- bb_clk
- bb_rst
- rx_i_signal
- rx_q_signal
- rx_iq_valid
- bb_gpio

## Outputs
- i_abs_add_q_abs
- agc_lock_change
- agc_lock_state
- rf_gain

## Calls

## Called By
- [btle_controller](btle_controller.md)
