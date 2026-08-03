# btle_rx

## Description
TODO: Add description

## Parameters
- SAMPLE_PER_SYMBOL = 8
- GFSK_DEMODULATION_BIT_WIDTH = 16
- LEN_UNIQUE_BIT_SEQUENCE = 32
- CHANNEL_NUMBER_BIT_WIDTH = 6
- CRC_STATE_BIT_WIDTH = 24
- NUM_BIT_PAYLOAD_LENGTH = 8
- RF_I_OR_Q_BIT_WIDTH = 16
- ENABLE_RX_ED_CCA = 0
- ENABLE_PKT_TIMING_ENFORCE = 0
- ENABLE_ABORT_ON_CRC_FAIL = 0
- PKT_ABORT_HOLD_CYCLES = 1
- PKT_FAIL_LIMIT = 1
- PKT_PRE_AA_TIMEOUT_US = 80
- PKT_MAX_US = 4000
- RX_CLK_HZ = 16000000
- RX_ED_THRESHOLD = 32'd0  (unresolved)
- RX_ED_WINDOW_SAMPLES = 128

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode [2:0]
- unique_bit_sequence [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]
- channel_number [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0]
- crc_state_init_bit [(CRC_STATE_BIT_WIDTH-1) : 0]
- i [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- q [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0]
- iq_valid
- magnitude [RF_I_OR_Q_BIT_WIDTH : 0]
- pdu_octet_mem_addr [NUM_BIT_PAYLOAD_LENGTH:0]

## Outputs
- hit_flag
- decode_run
- decode_end
- crc_ok
- best_phase [2:0]
- payload_length [(NUM_BIT_PAYLOAD_LENGTH-1):0]
- pdu_octet_mem_data [7:0]

## Inouts
- None

## Calls
- [btle_rx_core](btle_rx_core.md)
- [packet_abort_early_term](packet_abort_early_term.md)
- [packet_abort_on_crc_fail](packet_abort_on_crc_fail.md)
- [packet_timing_enforce](packet_timing_enforce.md)
- [rx_energy_detect_cca](rx_energy_detect_cca.md)
- [serial_in_ram_out](serial_in_ram_out.md)

## Called By
- [btle_phy](btle_phy.md)
