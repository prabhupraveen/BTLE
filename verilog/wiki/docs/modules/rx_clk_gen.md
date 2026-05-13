# rx_clk_gen

## Description
This utility module is responsible for creating a high-speed oversampling clock used by the UART receiver.  
- **Multi-Phase Sample Clock**: It generates a `sample_clk` pulse at a frequency typically 9 times higher than the target baud rate to allow for precise bit-center detection.  
- **Gated Operation**: The clock generation is managed by a state machine that only runs during active reception, staying idle otherwise to conserve resources.  
- **Flexible Scaling**: It uses module parameters to automatically calculate the necessary counter widths based on the provided system frequency and baud rate. 

## Inputs
- clk
- rst_n
- rx_start
- rx_done

## Outputs
- sample_clk

## Calls

## Called By
- [uart_frame_rx](uart_frame_rx.md)
