# rx_energy_detect_cca

## Description
TODO: Add description

## Parameters
- IQ_W = 16
- ACC_W = 32
- WINDOW_SAMPLES = 128
- MAG_W = 17

## Inputs
- clk
- rst
- i [IQ_W-1:0]
- q [IQ_W-1:0]
- iq_valid
- rx_magnitude [MAG_W-1:0]
- ed_threshold [ACC_W-1:0]

## Outputs
- cca_busy
- ed_level [ACC_W-1:0]
- ed_valid

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx](btle_rx.md)
