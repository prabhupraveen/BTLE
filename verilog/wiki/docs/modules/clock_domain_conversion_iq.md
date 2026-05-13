# clock_domain_conversion_iq

## Description
This module handles the safe transfer of complex I/Q signal data between the RF transceiver's clock domain (8 MHz) and the baseband processing clock domain (16 MHz).  
- **Rx Path Alignment**: On the receive path, it captures 8 MHz RF samples and presents them to the 16 MHz baseband domain, using a toggling valid signal to ensure the data rate remains consistent at 8 Msps.  
- **Tx Path Resizing**: On the transmit path, it takes narrow (8-bit) baseband I/Q samples, sign-extends them to match the wider RF interface requirements, and passes them into the 8 MHz RF clock domain.

## Inputs
- rf_clk
- rf_rst
- bb_clk
- bb_rst
- rf_gpio
- rx_iq_signal_ext
- rx_iq_valid_ext
- tx_i_signal
- tx_q_signal
- tx_iq_valid
- tx_iq_valid_last

## Outputs
- rx_i_signal
- rx_q_signal
- rx_iq_valid
- bb_gpio
- tx_iq_signal_ext
- tx_iq_valid_ext
- tx_iq_valid_last_ext

## Calls

## Called By
- [btle_controller](btle_controller.md)
