# symbol_timing_recovery_simple

## Description
TODO: Add description

## Parameters
- SPS = 8
- DEC_W = 32
- PH_W = 3
- UPDATE_PERIOD_SYM = 32

## Inputs
- clk
- rst
- decision_in [DEC_W-1:0]
- decision_valid
- update_period_sym_runtime [15:0]

## Outputs
- phase_sel [PH_W-1:0]
- sym_strobe
- decision_sym [DEC_W-1:0]

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx_core](btle_rx_core.md)
