# uart_frame_rx

## Description
This module implements a standard UART receiver that converts a serial bitstream into parallel data frames.
- **Oversampling and Detection**: It monitors the incoming serial line for a start bit (negative edge) and uses a sample clock to read each bit multiple times to ensure accuracy.  
- **FSM-Driven Reception**: It moves through states for the start bit, data bits, optional parity, and stop bits to reconstruct the original frame.  
- **Error Checking**: It calculates and verifies parity bits (if enabled) to detect transmission errors and asserts a "done" signal once a complete, valid frame is received. 

## Inputs
- clk
- rst_n
- uart_rx

## Outputs
- rx_frame
- rx_done
- frame_error

## Calls
- [rx_clk_gen](rx_clk_gen.md)

## Called By
- [btle_ll](btle_ll.md)
