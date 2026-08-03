# clock_domain_conversion_iq

## Description
TODO: Add description

## Parameters
- RF_IQ_BIT_WIDTH = 64
- RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4)  (= 16)
- IQ_BIT_WIDTH = 8
- GFSK_DEMODULATION_BIT_WIDTH = 16

## Inputs
- rf_clk
- rf_rst
- bb_clk
- bb_rst
- rf_gpio [7:0]
- rx_iq_signal_ext [(RF_IQ_BIT_WIDTH-1) : 0]
- rx_iq_valid_ext
- tx_i_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_q_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_iq_valid
- tx_iq_valid_last

## Outputs
- rx_i_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_q_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_iq_valid
- bb_gpio [7:0]
- tx_iq_signal_ext [(RF_IQ_BIT_WIDTH-1) : 0]
- tx_iq_valid_ext
- tx_iq_valid_last_ext

## Inouts
- None

## Calls
- None

## Called By
- [btle_controller](btle_controller.md)
