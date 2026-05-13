# packet_abort_on_crc_fail

## Description
This is a control module designed to save system processing time by aborting operations if broken packets are detected.
- **Failure Tracking**: It monitors the end of a packet decode and increments an internal counter if the CRC check fails.
- **Abort Trigger**: Once the consecutive failure count hits a programmable limit, it fires an abort pulse to reset or stop downstream receiver phases. It zeroes the counter if a good packet arrives.

## Inputs
- clk
- rst
- enable
- decode_end
- crc_ok

## Outputs
- abort_pulse
- fail_count

## Calls

## Called By
- [btle_rx](btle_rx.md)
