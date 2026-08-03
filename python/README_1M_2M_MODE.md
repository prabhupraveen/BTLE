# BLE 1M & 2M Mode Support - Implementation Guide

## Overview
Added **BLE 2M (2 Mbps)** PHY mode support alongside existing **1M (1 Mbps)** mode. Both modes tested with identical underlying TX/RX algorithms, bypassing normal connection/handshake requirements.

## Key Changes

### Core Library: `btlelib.py`
- Added `PHY_MODE` global variable ('1M' | '2M')
- Added `set_phy_mode(mode)` function to switch modes
  - 1M: 8 Msps ÷ 1 Mbps = **8 samples/symbol**
  - 2M: 8 Msps ÷ 2 Mbps = **4 samples/symbol**
- Auto-clears cached VCO/Gaussian filter tables on mode switch (ensures correct recalculation)

### How It Works
```python
import btlelib as bl

# Default: 1M mode
bl.set_phy_mode('1M')  # SAMPLE_PER_SYMBOL = 8
tx_i, tx_q = bl.btle_tx(pdu_bit, channel, crc_init, access_addr)

# Switch to 2M
bl.set_phy_mode('2M')  # SAMPLE_PER_SYMBOL = 4
tx_i, tx_q = bl.btle_tx(pdu_bit, channel, crc_init, access_addr)
```

## New Test Scripts

### 1. `test_vector_btle_1m_2m.py`
Single example test with switchable mode
```bash
python3 test_vector_btle_1m_2m.py 0 20 0 0 1M   # Example 0, SNR=20dB, no PPM, no delay, 1M mode
python3 test_vector_btle_1m_2m.py 0 20 0 0 2M   # Same but 2M mode
```
- Generates TX/RX test vectors
- Plots transmit & receive signals
- Saves IQ samples, configuration, CRC results per mode

### 2. `generate_btle_verilog_batch_1m_2m.py`
Batch golden test vectors for 3 scenarios (ADV, DATA, CONN_UPDATE)
```bash
python3 generate_btle_verilog_batch_1m_2m.py
```
- Generates vectors for both 1M & 2M simultaneously
- Output dir: `test_vectors_batch/`
- Structure:
  ```
  test_vectors_batch/
  ├── case0_adv_ch37_1M/
  ├── case0_adv_ch37_2M/
  ├── case1_conn_update_ch9_1M/
  ├── case1_conn_update_ch9_2M/
  └── ...
  ```

### 3. `test_btle_ber_1m_2m.py`
Bit-error-rate sweep with mode parameter
```bash
python3 test_btle_ber_1m_2m.py 0 1M    # PPM=0, 1M mode
python3 test_btle_ber_1m_2m.py 20 2M   # PPM=20, 2M mode
```

### 4. `test_alignment_with_btle_sdr_1m_2m.py`
TX alignment verification
```bash
python3 test_alignment_with_btle_sdr_1m_2m.py 0 1M
python3 test_alignment_with_btle_sdr_1m_2m.py 0 2M
```

### 5. `test_btle_rx_by_captured_iq_1m_2m.py`
RX decode from captured CSV IQ
```bash
python3 test_btle_rx_by_captured_iq_1m_2m.py waveform.csv 37 D6BE898E 555555 1M
python3 test_btle_rx_by_captured_iq_1m_2m.py waveform.csv 37 D6BE898E 555555 2M
```

## Implementation Details

### Mode Switching Mechanism
When `set_phy_mode()` called:
1. Updates global `PHY_MODE` & `SAMPLE_PER_SYMBOL`
2. Clears cached modulation tables:
   - VCO sin/cos lookup tables (depend on `SAMPLE_PER_SYMBOL`)
   - Gaussian filter taps (depend on `SAMPLE_PER_SYMBOL`)
3. Next TX/RX call regenerates tables with correct parameters

### Why Clear Cache?
- VCO table size = `scale_up_factor × SAMPLE_PER_SYMBOL / (MODULATION_INDEX/2)`
- Gaussian filter tap count = `NUM_SYMBOL_GAUSS_FILTER_SPAN × SAMPLE_PER_SYMBOL + 1`
- Must rebuild both when sample rate halves (1M→2M)

### Test Vector Output
Config file includes PHY mode:
```
# btle_config.txt
40       # PDU length hex
25       # channel hex
555555   # CRC init hex
D6BE898E # access address hex
1M       # PHY mode (NEW)
```

## Physical Layer Assumptions

**1M PHY (BLE Classic Advertisement)**
- Symbol rate: 1 Mbps
- Oversampling: 8x (8 Msps hardware)
- Gaussian filter: BT=0.5, span=2 symbols

**2M PHY (BLE 2M PHY)**
- Symbol rate: 2 Mbps  
- Oversampling: 4x (same 8 Msps hardware)
- Gaussian filter: BT=0.5, span=2 symbols (same time-domain shape, tighter freq spacing)
- **No connection/handshake** — direct peer-to-peer TX@2M ↔ RX@2M bypass

## Comparison: 1M vs 2M

| Feature | 1M | 2M |
|---------|----|----|
| Bitrate | 1 Mbps | 2 Mbps |
| Samples/Symbol | 8 | 4 |
| Symbol time | 1 µs | 0.5 µs |
| VCO table size | ~1024 entries | ~512 entries |
| Gauss filter taps | 17 | 9 |
| SNR requirement (typical) | ~10 dB | ~14 dB (more sensitive) |

## Backward Compatibility
- Original scripts still work (default to 1M)
- `SAMPLE_PER_SYMBOL = 8` at module load (1M default)
- Explicit `set_phy_mode()` required to use 2M

## Testing Checklist
- [x] 1M TX/RX test vectors generated
- [x] 2M TX/RX test vectors generated  
- [x] Mode switching clears caches
- [x] BER sweep supports both modes
- [x] Signal plots labeled by mode
- [x] Config files include mode flag
- [ ] Verilog testbenches accept mode parameter (future)
- [ ] Compare 1M vs 2M BER curves

## Notes
- Both modes use same baseband DSP (modulation, CRC24, scrambler)
- Only difference: symbol rate (and thus sample-per-symbol decimation in RX)
- No frequency hopping / connection setup — raw PHY test only
- Test vectors save to mode-specific directories to avoid collisions
