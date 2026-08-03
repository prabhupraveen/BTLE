# btle_controller_wrapper

## Description
TODO: Add description

## Parameters
- CLK_FREQUENCE = 16_000_000  (= 16000000)
- BAUD_RATE		= 115200
- PARITY = "NONE"  (unresolved)
- FRAME_WD		= 8
- CRC_STATE_BIT_WIDTH = 24
- CHANNEL_NUMBER_BIT_WIDTH = 6
- SAMPLE_PER_SYMBOL = 8
- GAUSS_FILTER_BIT_WIDTH = 16
- NUM_TAP_GAUSS_FILTER = 17
- VCO_BIT_WIDTH = 16
- SIN_COS_ADDR_BIT_WIDTH = 11
- IQ_BIT_WIDTH = 8
- GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32

## Inputs
- clk
- rst
- clkb
- uart_rx
- rx_i_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_q_signal [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- rx_iq_valid
- baremetal_phy_intf_mode

## Outputs
- uart_tx
- tx_i_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_q_signal [(IQ_BIT_WIDTH-1) : 0]
- tx_iq_valid
- tx_iq_valid_last
- fake_pins [31:0]

## Inouts
- None

## Calls
- [btle_controller](btle_controller.md)

## Called By
- None
