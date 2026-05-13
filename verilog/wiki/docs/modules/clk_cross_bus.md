# clk_cross_bus

## Description
This module serves as a bridge to transfer data between two different clock domains, ensuring stability and preventing metastability during the transfer.
- **Dual-Clock Storage**: It primarily uses a simple dual-port RAM (`sdpram_two_clk`) to store data from the write clock domain and retrieve it in the read clock domain.  
- **Alternative FIFO Path**: It contains an optional asynchronous FIFO implementation (`xpm_fifo_async`) that includes built-in synchronization stages and status flags like full, empty, and overflow.  
- **Edge Detection**: In the FIFO mode, it monitors the input data for changes to trigger write enable signals, ensuring data is only pushed when updated. 

## Inputs
- write_clk
- read_clk

## Outputs

## Calls
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_ll](btle_ll.md)
