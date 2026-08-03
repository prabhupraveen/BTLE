# TODO

## Open Issues

- `ble_send_cmd -m` is not working.
  - `ble_send_cmd.c` does parse `-m` and sends `control = 1`, but its payload format is `[pdu_len][pdu_bytes]`.
  - Current `btle_ll.c` `control == 1` path does not parse `[pdu_len][pdu_bytes]`; it treats payload as a C-string (`msg_ptr`) and only logs text.
  - Current `btle_ll.c` TX path is still TODO (`TX trigger`/DMA not implemented), so even accepted `control = 1` data will not transmit over air yet.

-- remote nrf MAC - ce:41:48:9b:2d:f2