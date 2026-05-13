# packet_timing_enforce

## Description
This module provides a timeout mechanism to ensure the receiver does not hang indefinitely while waiting for or processing a packet.  
- **Preamble/AA Timeout**: It tracks how long the system waits for a valid Access Address (AA) and triggers an abort if no "hit" is detected within a set window.  
- **Maximum Duration Guard**: Once a packet begins, it enforces a maximum time limit to prevent the receiver from processing excessively long or malformed data streams.  
- **State-Specific Counters**: It utilizes independent internal counters to manage the two distinct timing phases: waiting for detection and active packet reception.

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

## Calls

## Called By
- [btle_rx](btle_rx.md)
