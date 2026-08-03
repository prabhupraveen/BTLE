# uart_frame_rx

## Description
TODO: Add description

## Parameters
- CLK_FREQUENCE = 50_000_000  (= 50000000)
- BAUD_RATE		= 9600
- PARITY = "NONE"  (unresolved)
- FRAME_WD		= 8

## Inputs
- clk
- rst_n
- uart_rx

## Outputs
- rx_frame [FRAME_WD-1:0]
- rx_done
- frame_error

## Inouts
- None

## Calls
- [rx_clk_gen](rx_clk_gen.md)

## Called By
- [btle_ll](btle_ll.md)
- [btle_ll_dummy](btle_ll_dummy.md)
