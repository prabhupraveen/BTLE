# btle_tx

## Description
This is the top-level BTLE transmitter module that converts digital payload data into a frequency-modulated signal ready for radio transmission.  
- **Packet Assembly**: It constructs the physical packet by prepending the required preamble and access address to the data payload retrieved from memory.  
- **Processing Pipeline**: The module sequences the bitstream through a CRC-24 generator and a data scrambler  to comply with Bluetooth specifications.  
- **Modulation Control**: It feeds the processed bitstream into a GFSK modulator , managing the transition from idle states to active transmission and back.  
- **Integrated PHY Testing**: It includes built-in test modes to generate standard patterns such as PRBS9, alternating 1/0 bits, or continuous 1s/0s for hardware calibration.  
- **Dual-Clock RAM**: It utilizes a dual-port RAM buffer to allow packet data to be written by a high-speed system clock and read at the baseband symbol rate. 

## Inputs
- clk
- rst
- clkb
- phy_2m_mode
- phy_test_mode
- gauss_filter_tap_index
- gauss_filter_tap_value
- cos_table_write_address
- cos_table_write_data
- sin_table_write_address
- sin_table_write_data
- preamble
- access_address
- crc_state_init_bit
- crc_state_init_bit_load
- channel_number
- channel_number_load
- pdu_octet_mem_data
- pdu_octet_mem_addr
- tx_start

## Outputs
- i
- q
- iq_valid
- iq_valid_last
- phy_bit
- phy_bit_valid
- phy_bit_valid_last
- bit_upsample
- bit_upsample_valid
- bit_upsample_valid_last
- bit_upsample_gauss_filter
- bit_upsample_gauss_filter_valid
- bit_upsample_gauss_filter_valid_last

## Calls
- [crc24](crc24.md)
- [gfsk_modulation](gfsk_modulation.md)
- [scramble](scramble.md)
- [sdpram_two_clk](sdpram_two_clk.md)

## Called By
- [btle_phy](btle_phy.md)
