# packet_abort_early_term

## Description
TODO: Add description

## Parameters
- HOLD_CYCLES = 1

## Inputs
- clk
- rst
- abort_req
- timing_abort
- decode_end
- crc_ok
- abort_on_crc_fail

## Outputs
- abort_pulse
- aborted
- crc_fail_seen

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx](btle_rx.md)
