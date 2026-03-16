# TODO

## Open Issues

- `ble_send_cmd -m` is not working.
  - Confirmed sender-side gap in `ble_send_cmd.c`: `getopt` string is `"t:p:n:c:a:"`, so `-m` is ignored as an invalid option.
  - `ble_send_cmd_Dummy.c` does parse `-m` and sends `control = 1`, but its payload format is `[pdu_len][pdu_bytes]`.
  - Current `btle_ll.c` `control == 1` path does not parse `[pdu_len][pdu_bytes]`; it treats payload as a C-string (`msg_ptr`) and only logs text.
  - Current `btle_ll.c` TX path is still TODO (`TX trigger`/DMA not implemented), so even accepted `control = 1` data will not transmit over air yet.
  - Integration caution: GUI executes `./ble_send_cmd` binary; editing/adding `ble_send_cmd_Dummy.c` alone has no effect unless compiled and substituted.

- Wireshark launch from GUI is not consistently reliable.
  - Observed behavior:
    - Running GUI as root (`sudo python control_gui.py`) works reliably.
    - Running GUI as normal user and using in-GUI sudo password for capture can fail with read/pipe/permission errors.
  - Likely causes to verify:
    - `sudo -S` non-interactive behavior differences in subprocess pipeline.
    - environment/display/X11/Wayland permissions when mixed privilege processes are piped.
    - whether root-owned producer process and user-owned Wireshark consumer have incompatible runtime conditions.
  - Immediate operational guidance: run whole GUI as sudo until capture path is hardened.

## Protocol / UX Improvements

- Support updating up to 3 BLE register values (`-a`, `-c`, `-n`) in one user action.
  - Option A (quick): GUI sends up to three sequential commands (one per register).
  - Option B (clean protocol): add multi-register command format in both `ble_send_cmd.c` and `btle_ll.c`.
  - Option C (hybrid): multi-register when supported; fallback to sequential single-register writes.

- Command ACK visibility improvements.
  - Add clearer ACK success/failure summaries in GUI log per command sent.

- Capture diagnostics in GUI.
  - Surface explicit warnings when UDP packets are flowing but Wireshark is not displaying them (possible firewall/filtering issue).

## Validation Checklist (after fixes)

- Verify `-m` end-to-end with one agreed format between sender and receiver (raw message vs `[pdu_len][pdu]`).
- Verify `control == 1` performs real TX trigger path, not logging-only.
- Verify `{ -a, -c, -n }` multi-update behavior matches selected implementation.
- Verify Wireshark autostart in both modes:
  - GUI started as sudo
  - GUI started as user + in-app sudo path
- Verify `config.json` still excludes sensitive credentials.
