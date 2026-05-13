# btle_rx

## Description
This is the top-level Bluetooth Low Energy (BTLE) receiver module that integrates multiple sub-components to process raw radio samples into validated data packets.  
- **Parallel Multi-Phase Decoding**: It distributes incoming I/Q samples into eight parallel decoding "phases" to account for symbol timing uncertainty.  
- **Core Orchestration**: It manages eight instances of `btle_rx_core` , tracking which phase successfully detects a packet header ("hit") and yields a valid CRC.  
- **Best-Phase Selection**: The module automatically selects the data from the phase that first achieves a successful CRC check, outputting that phase's payload and length.  
- **Advanced Guarding**: It integrates optional features like Clear Channel Assessment (CCA) , timing enforcement to prevent hangs , and automatic abort logic for failed packets.  
- **Memory Interface**: Validated packet data (PDU) is stored in internal RAM, which can be read by an external system using a separate clock.  

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode
- unique_bit_sequence
- channel_number
- crc_state_init_bit

## Outputs
- hit_flag
- decode_run
- decode_end
- crc_ok
- best_phase
- payload_length
- pdu_octet_mem_data

## Calls
- [btle_rx_core](btle_rx_core.md)
- [packet_abort_early_term](packet_abort_early_term.md)
- [packet_abort_on_crc_fail](packet_abort_on_crc_fail.md)
- [packet_timing_enforce](packet_timing_enforce.md)
- [rx_energy_detect_cca](rx_energy_detect_cca.md)
- [serial_in_ram_out](serial_in_ram_out.md)

## Called By
- [btle_phy](btle_phy.md)
