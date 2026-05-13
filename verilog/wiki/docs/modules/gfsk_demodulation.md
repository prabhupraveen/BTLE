# gfsk_demodulation

## Description
This module converts raw I/Q radio samples back into digital bits by calculating the frequency shift between successive samples.  
- **Delay-Line Discriminator**: It maintains a history of the current and previous I/Q samples to perform a cross-multiplication ($I_0Q_1 - I_1Q_0$), which approximates the phase change (frequency) of the signal.  
- **Mode-Specific Shaping**: It includes a bit-shifting stage to normalize the signal magnitude when switching between 1M and 2M PHY modes.  
- **Slicing**: It compares the resulting frequency estimate against a programmable threshold to decide if the received bit is a '0' or a '1'. 

## Inputs
- clk
- rst
- phy_2m_mode
- decision_threshold

## Outputs

## Calls

## Called By
- [btle_rx_core](btle_rx_core.md)
