# uart_frame_tx

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
- frame_en
- data_frame [FRAME_WD-1:0]

## Outputs
- tx_done
- uart_tx

## Inouts
- None

## Calls
- [tx_clk_gen](tx_clk_gen.md)

## Called By
- [btle_ll](btle_ll.md)
- [btle_ll_dummy](btle_ll_dummy.md)
