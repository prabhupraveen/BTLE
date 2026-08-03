# packet_timing_enforce

## Description
TODO: Add description

## Parameters
- CLK_HZ = 16000000
- PREAMBLE_AA_TIMEOUT_US = 80
- PKT_MAX_US = 4000

## Inputs
- clk
- rst
- arm
- hit_flag
- decode_end

## Outputs
- abort
- timeout_wait_hit
- timeout_in_pkt

## Inouts
- None

## Calls
- None

## Called By
- [btle_rx](btle_rx.md)
