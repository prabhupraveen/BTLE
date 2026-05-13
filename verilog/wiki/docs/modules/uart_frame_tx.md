# uart_frame_tx

## Description
This is the transmitter counterpart to the UART receiver, responsible for serializing parallel data for transmission.
- **Frame Construction**: It takes a parallel data frame and wraps it with the necessary UART protocol elements, including a start bit (low), data bits, an optional parity bit, and a stop bit (high).  
- **Baud Rate Control**: It utilizes a baud rate clock generator to ensure that each bit is driven onto the serial line for the correct duration.  
- **Shift Register Logic**: It uses a state machine to shift data bits out one by one, starting from the least significant bit (LSB).

## Inputs
- clk
- rst_n
- frame_en
- data_frame

## Outputs
- tx_done
- uart_tx

## Calls
- [tx_clk_gen](tx_clk_gen.md)

## Called By
- [btle_ll](btle_ll.md)
