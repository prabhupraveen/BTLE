# BLE PHY Validation Framework (nRF54 + AntSDR + Wireshark)

## Scope
Validation of custom BLE PHY (RX-first architecture), progressing from BLE 1M to BLE 5.4, using:
- TX reference: nRF54 firmware (advertising / DTM / custom modes)
- Optional TX: phone / laptop BLE devices
- RX under test: AntSDR-based PHY
- Output: full packet capture streamed to Wireshark (PCAP format)

The RX pipeline reconstructs full BLE packets (Access Address + PDU + CRC) and forwards only CRC-valid packets to Wireshark.

---

## Entities Used
- **nRF54**: test transmitter
- **AntSDR**: device under test (DUT)
- **Wireshark**: analysis sink
- **Phone/Laptop verifier**: optional side verifier (for example, nRF Connect)

---

## Wireshark Output Expectations

From RX pipeline (based on implementation):
- Only CRC-valid packets are forwarded to Wireshark
- Each packet contains:
  - Access Address (4 bytes)
  - Full PDU
  - CRC (3 bytes)
- Timestamped packets
- Link-layer decoding visible:
  - ADV_IND, ADV_SCAN_IND, etc.
  - Source (AdvA)
  - Payload fields (name, flags, etc.)

### General Pass Criteria (All Tests)
- Packets visible in Wireshark
- Correct protocol decoding (Bluetooth LE Link Layer)
- No malformed packet warnings (unless intentional)
- Stable packet rate

---

# TEST SUITE

---

## TEST 1 — ADV_BASIC_1M - beacon1m.hex

### Objective
Validate baseline 1M PHY packet detection and decoding.

### TX (nRF54)
- Standard connectable advertising on channels 37/38/39
- Access Address: 0x8E89BED6

### RX Expectation
- Detect preamble (1 byte)
- Lock Access Address 0x8E89BED6
- Decode full packet (AA + PDU + CRC)

### Wireshark Expectation
- Continuous ADV_IND packets
- Visible:
  - Advertiser address
  - Device name
  - Flags
- No CRC errors shown

### Pass Criteria
- Packet decode rate >= 95% with correct addresses and CRC

### Failures / Causes
- No packets: RF tuning / channel / gain / CFO issue
- Wrong AA: bit alignment issue
- Malformed packets: demodulation or framing issue

---

## TEST 2 — ADV_MULTI_DEVICE - beacon1m.hex

### Objective
Validate multi-source decoding from multiple BLE advertisers.

### TX (nRF54 + Phone + Laptop)
- nRF54 advertising
- Phone BLE enabled (scanning or advertising)
- Laptop BLE active

### RX Expectation
- Simultaneous decoding of multiple advertisers

### Wireshark Expectation
- Multiple device addresses
- Interleaved packets from different sources

### Failures / Causes
- Only one device visible: sensitivity / filtering issue
- Packet loss: buffer overflow / timing issue

---

## TEST 3 — ACCESS_ADDRESS_VARIANT - aaTest.hex

### Objective
Validate lock and decode capability for arbitrary access addresses.

### TX (nRF54)
- Transmit with non-standard Access Address via custom firmware or DTM variant

### RX Expectation
- Discover and lock arbitrary Access Address
- Decode PDU using discovered Access Address

### Wireshark Expectation
- Valid decodes for custom Access Address traffic

### Pass Criteria
- Correct Access Address extraction and successful PDU decode

### Failures / Causes
- Correlator assumes fixed Access Address
- Insufficient correlator width/search strategy

---

## TEST 4 — CHANNEL_SWEEP - channelTest.hex

### Objective
Validate channel tuning across BLE advertising channels.

### TX (nRF54)
- Advertising enabled

### RX Expectation
- Correct reception on:
  - Channel 37 (2402 MHz)
  - Channel 38 (2426 MHz)
  - Channel 39 (2480 MHz)

### Wireshark Expectation
- Packets appearing from all channels over time

### Pass Criteria
- All three channels decoded with comparable reliability

### Failures / Causes
- Missing channel: LO tuning / calibration / channel map issue

---

## TEST 5 — CRC_VALIDATION - crcTest.hex

### Objective
Validate CRC correctness and filtering behavior.

### TX (nRF54)
- Set A: standard valid advertising payloads
- Set B: intentionally corrupted payloads (bit flips)

### RX Expectation
- Correct CRC computation
- Accept valid packets
- Reject or flag corrupted packets

### Wireshark Expectation
- Only valid packets appear (or corrupted packets explicitly flagged if exported)

### Pass Criteria
- 100% valid packets accepted
- 100% corrupted packets rejected/flagged

### Failures / Causes
- CRC mismatch: polynomial / bit-order / endianness issue
- Excess packet drop: timing or noise

---

## TEST 6 — LOW_SNR

### Objective
Validate decode performance under low SNR.

### TX (nRF54)
- Standard advertising

### Setup
- Add attenuation, increase distance, or inject calibrated noise

### RX Expectation
- Reduced packet rate but stable decode behavior

### Wireshark Expectation
- Fewer packets but still valid
- No malformed frames under expected operating threshold

### Pass Criteria
- BER <= target at design SNR (for example, 0.1% around expected threshold)

### Failures / Causes
- Complete loss: sensitivity issue
- Burst errors: weak filtering or demod threshold tuning

---

## TEST 7 — FREQ_OFFSET

### Objective
Validate frequency offset tolerance and CFO correction.

### TX (nRF54 / Phone)
- Normal operation (natural ppm offset)
- Optional controlled offset cases (for example, +/-50 ppm, +/-100 ppm where available)

### RX Expectation
- Decode despite +/-20 to +/-50 ppm baseline offset
- Maintain usable decode with controlled offset conditions

### Wireshark Expectation
- Stable packet decoding with acceptable BER trend

### Pass Criteria
- Reliable decode at +/-50 ppm with minimal BER penalty

### Failures / Causes
- No lock: CFO estimation/correction failure
- BER spike: narrow filtering or LO calibration issue

---

## TEST 8 — CONTINUOUS_TX_1M (DTM)

### Objective
Validate continuous demodulation stability in 1M DTM mode.

### TX (nRF54)
- Direct Test Mode (continuous TX, 1M PHY)

### RX Expectation
- Continuous packet stream
- No sync loss
- No buffer overflows during sustained run

### Wireshark Expectation
- High-rate packet stream
- No malformed packets

### Pass Criteria
- Stable demodulation for configured duration (for example, 60 s)

### Failures / Causes
- Sync drops: timing recovery issue
- Packet boundary errors: framing logic issue

---

# 2M PHY TESTS

---

## TEST 9 — DTM_2M_BASIC

### Objective
Validate 2M PHY packet detection and decode.

### TX (nRF54)
- DTM TX with PHY = 2M

### RX Expectation
- Adapt to:
  - 2 Msps symbol rate
  - 2-byte preamble
- Auto-handle PHY timing changes
- Correct packet detection and decode

### Wireshark Expectation
- Continuous valid packets
- No decoding errors
- PHY metadata indicates 2M when available

### Pass Criteria
- Successful decode of 2M packets with valid CRC

### Failures / Causes
- No packets: still using 1M timing
- CRC fail: symbol timing or preamble handling mismatch

---

## TEST 10 — PHY_SWITCH

### Objective
Validate dynamic PHY handling when TX alternates 1M and 2M.

### TX (nRF54)
- Alternate bursts:
  - 1M (advertising)
  - 2M (DTM)

### RX Expectation
- Detect PHY mode dynamically per burst
- Reconfigure demod chain without lockup

### Wireshark Expectation
- Valid packets in both modes (separate runs or controlled switching)

### Pass Criteria
- Correct decode across alternated bursts with bounded switching latency

### Failures / Causes
- Only one PHY works: no PHY discrimination
- State lockup: reconfiguration/state-machine issue

---

## TEST 11 — TIMING_STRESS_2M

### Objective
Validate timing recovery robustness at 2M.

### TX (nRF54)
- Continuous 2M transmission
- Optional controlled drift/jitter cases

### RX Expectation
- Stable symbol timing
- Low BER under expected drift conditions

### Wireshark Expectation
- Continuous valid packet stream

### Pass Criteria
- BER and decode rate within thresholds for expected ppm drift

### Failures / Causes
- Timing loop instability
- Insufficient oversampling usage

---

# EDGE CASE TESTS

---

## TEST 12 — MOD_TOLERANCE

### Objective
Validate tolerance to non-standard modulation settings.

### TX (nRF54)
- Use custom firmware to vary deviation, modulation index, or BT product (where supported)

### RX Expectation
- Decode within documented tolerance envelope
- Flag out-of-envelope behavior

### Wireshark Expectation
- Valid packets inside tolerance range
- Graceful degradation outside range

### Failures / Causes
- Fixed matched-filter assumptions
- Hard-coded demod constants

---

## TEST 13 — INTERFERENCE_ENV

### Objective
Validate robustness under co-channel and adjacent-channel interference.

### TX
- nRF54 + phone + laptop active simultaneously
- Optional external interferer (signal source)

### RX Expectation
- Partial degradation only
- No receiver lockup

### Wireshark Expectation
- Mixed packets, some loss acceptable

### Failures / Causes
- Total loss: poor filtering/selectivity
- AGC instability / spectral leakage

---

## TEST 14 — GAP_RECOVERY

### Objective
Validate recovery from burst loss and long packet gaps.

### TX (nRF54 / Phone / Laptop)
- Bursty traffic with intentional long/randomized gaps

### RX Expectation
- Re-acquire sync quickly after gaps
- No lockups

### Wireshark Expectation
- Bursty packet arrivals handled correctly
- Recovery visible after idle periods

### Pass Criteria
- Re-acquisition within configurable packet count after gap

### Failures / Causes
- Buffer overflow
- State machine deadlock
- Persistent stale state flags

---

## TEST 15 — LONG_RUN_STABILITY

### Objective
Validate long-duration operation.

### TX
- Continuous advertising (nRF54 + phone)

### RX Expectation
- Stable operation over hours

### Wireshark Expectation
- Continuous packet stream
- No timestamp anomalies

### Failures / Causes
- Memory leaks
- Drift accumulation

---

# Firmware Variants (nRF54)

- **ADV_STANDARD**: standard advertising on channels 37/38/39 (1M)
- **ADV_CUSTOM_AA**: advertising with arbitrary Access Address
- **DTM_1M**: Direct Test Mode 1M continuous/burst TX
- **DTM_2M**: Direct Test Mode 2M continuous/burst TX
- **STRESS_TX**: high-duty-cycle / jittered timing TX
- **MOD_VARIANT**: non-standard modulation/deviation TX

Implementation note:
- Each firmware variant should expose start/stop control via console (UART/RTT) and parameters (channel, payload length, Access Address, PHY)

---

# AntSDR Requirements

- Tunable RF front-end covering 2402-2480 MHz
- Sampling/decimation chain supporting 1 Msps and 2 Msps operation (or oversampled equivalent)
- Preamble detector configurable for 1-byte (1M) and 2-byte (2M) preambles
- Access Address correlator able to search variable values
- CRC verifier matching BLE polynomial and bit ordering
- CFO estimator and corrector tolerant to at least +/-100 ppm
- Timing recovery loop appropriate for 1M and 2M symbol rates
- Packet exporter to Wireshark (PCAP or radiotap) with PHY metadata (channel, sample rate, PHY)
- State machine for dynamic PHY selection and graceful reconfiguration
- Logging for BER, sync events, CFO, SNR, timestamps

---

# Metrics

Core metrics:
- Packet detection rate
- CRC success rate
- BER (measured/derived)
- Sync loss and reacquisition events
- Frequency offset tolerance
- SNR threshold

Per-run capture set:
- Timestamped packet logs (PCAP)
- Decode success rate (%)
- CRC pass/fail counts
- BER estimate
- CFO estimate (ppm)
- SNR estimate (dB)
- PHY switch/reconfiguration latency (where applicable)

---

# Pass/Fail Thresholds

Suggested starting thresholds:
- Packet decode rate >= 95% (baseline)
- CRC success >= 99% in clean channel
- BER <= 0.1% at design SNR and target ppm
- Re-acquisition latency < 3 packets after gap or PHY switch
- CFO handling: decode at +/-50 ppm with minimal BER penalty

---

# Failure Diagnosis Checklist

- No packets detected: verify RF tuning, antenna, gain, channel selection
- Access Address mismatch/no lock: expand correlator window, verify bit alignment and bit order
- CRC always failing: verify polynomial, bit ordering, byte/bit endianness
- Works at 1M but fails at 2M: verify preamble length, timing, oversampling, filter bandwidth
- Intermittent decode: inspect AGC behavior, jitter, buffering, host load
- High CFO estimates: check LO calibration and thermal drift

---

# Test Execution Template

1. Prepare nRF54 firmware variant and parameters (channel, Access Address, PHY).
2. Start AntSDR capture and Wireshark streaming.
3. Start selected TX mode according to test plan.
4. Optionally run phone/laptop verifier actions.
5. Collect PCAP and diagnostics for configured duration.
6. Compute metrics and compare with thresholds.
7. Record pass/fail and anomalies.

---

# Notes for Phone/Laptop Roles

- **Phone (Android/iOS)**: optional verifier for connection-based PHY validation (for example, request PHY changes using nRF Connect)
- **Laptop**: run Wireshark analysis and optional host-side control path (HCI/serial)

---

# Deliverables per Test

- nRF54 build binary and flash script (with parameters)
- AntSDR capture script and Wireshark PCAP output
- Expected-result file: expected PDUs, Access Address, CRC status, PHY metadata
- Failure reproduction notes and likely root causes

---

# Key Validation Progression

1. 1M advertising baseline and CRC validation
2. Multi-device and Access Address flexibility
3. DTM 1M stability
4. DTM 2M and dynamic PHY switching
5. Stress and edge-case hardening
6. Automation of orchestration, aggregation, and reporting

---