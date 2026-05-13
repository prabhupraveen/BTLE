# tx_clk_gen

## Description
This module provides the precision timing required for a UART transmitter to send bits at the correct speed.  
- **Baud Rate Pulse**: It generates a single-cycle pulse (`bps_clk`) exactly once per bit period to drive the shifting of serial data.  
- **Transmission Synchronization**: It operates based on a state machine that synchronizes with the start of a transmission and resets when the data frame is fully sent.  
- **Rate Calculation**: It derives the bit period by dividing the system clock frequency by the target baud rate.

## Inputs
- clk
- rst_n
- tx_done
- tx_start

## Outputs
- bps_clk

## Calls

## Called By
- [uart_frame_tx](uart_frame_tx.md)
