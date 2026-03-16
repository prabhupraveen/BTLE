# BLE FPGA Control GUI (`control_gui.py`)

Professional GUI workflow for controlling and observing BLE FPGA traffic using:
- `btle_ll` (remote on AntSDR via SSH)
- `ble_fpga_ctl` (local UDP-to-PCAP bridge)
- `ble_send_cmd` (local command sender)
- Wireshark (local packet viewer)

---

## 1) Run the GUI (recommended with sudo)

Run the GUI with `sudo`.

> Why: this is mainly to avoid capture/permission friction for Wireshark and packet piping.

---

## 1.1) Pre-flight alerts

Before the main window opens, two alerts appear.
Read them and confirm:
- VPN connectivity check reminder
- Binary rebuild reminder

These dialogs are intentional safety checks.

---

## 2) Configure first (top-left Config menu)

Open **Config → Open Configuration…** and set values carefully, especially:
- AntSDR IP
- Host IP
- Command/Data ports
- SSH username/password for remote AntSDR login

You typically do **not** need to fill root password if you already launched GUI with `sudo`.

> Note: Wireshark auto-open may still be unreliable in some environments; tracked in TODO.

---

## 3) Config persistence and credential safety

Saving config creates/updates `config.json` for persistent settings.

Security behavior:
- Root/sudo password is **not** persisted
- SSH credentials are **not** persisted

On next launch, sensitive fields are intentionally blank.

---

## 4) Status lights (top row)

The status indicators provide quick health feedback for:
- VPN
- AntSDR reachability
- SSH / `btle_ll`
- Capture pipeline

Treat them as live operational hints.

---

## 5) Verify reachability with Ping

Use **Ping AntSDR** before starting capture/control.
If ping fails, resolve connectivity first.

---

## 6) Start capture first

Click **Start Capture + Wireshark**.
This launches the local capture bridge and opens Wireshark.

---

## 7) Start `btle_ll`

Click **Start btle_ll**.
This starts remote `btle_ll` over SSH, which reads packets from hardware and streams them to host.

You should see:
- runtime logs in GUI
- packets appearing in Wireshark

---

## 8) Send commands

Use **Send Command** to send register updates (`-n`, `-a`, `-c`, and related fields).

Known limitation on message TX (`-m`):
- Current production `ble_send_cmd.c` does not parse `-m` yet.
- Current `btle_ll.c` `control==1` path is currently logging-oriented and does not complete real TX trigger logic yet.

---

## 9) Troubleshooting

### 9.a) Nothing visible in Wireshark

Possible cause: firewall filtering incoming UDP.

Validate raw packet arrival with:

`tcpdump -i tun0 udp port 50001`

Run this while `btle_ll` is ON (started via GUI).

Interpretation:
- If packets appear in `tcpdump` but not in Wireshark, likely local filtering/firewall/display path issue.

### 9.b) Ping failing

If ping fails, there is likely routing/connectivity issue between your device and the remote AntSDR network (LAN/VPN path).

Check:
- VPN tunnel status
- route table
- destination IP correctness
- ACL/firewall in path

---

## Runtime Notes

- Keep binaries (`ble_fpga_ctl`, `ble_send_cmd`) in the same directory as `control_gui.py`.
- Ensure remote `btle_ll` binary exists in configured remote working directory.

---

## Related files

- `control_gui.py`
- `ble_send_cmd.c`
- `ble_fpga_ctl.c`
- `btle_ll.c`
- `config.json`
- `TODO.md`
