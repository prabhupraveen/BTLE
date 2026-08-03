# gfsk_demodulation

## Description
TODO: Add description

## Parameters
- GFSK_DEMODULATION_BIT_WIDTH = 16

## Inputs
- clk
- rst
- phy_2m_mode
- i [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- q [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- iq_valid

## Outputs
- signal_for_decision [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- signal_for_decision_valid
- phy_bit
- bit_valid

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx_core](btle_rx_core.md)
