# packet_abort_early_term

## Description
This module acts as a supervisory controller that decides when to stop the packet reception process early due to errors or external requests.  
- **Abort Source Integration**: It monitors multiple signals including external requests, timing timeouts, and CRC status to trigger a reset of the receiver chain.  
- **Error-Based Termination**: When enabled, it can automatically abort a packet if a CRC failure is detected at the end of a decode cycle.  
- **Reset Pulse Generation**: It produces a timed reset pulse (`abort_pulse`) to ensure downstream logic is properly cleared after an abort event.

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

## Calls

## Called By
- [btle_rx](btle_rx.md)
